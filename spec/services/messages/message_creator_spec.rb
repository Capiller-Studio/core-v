# frozen_string_literal: true

require "rails_helper"

RSpec.describe Messages::MessageCreator, type: :service do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  let(:image_file) do
    Rack::Test::UploadedFile.new(
      StringIO.new("fake-image-data"),
      "image/png",
      original_filename: "test.png"
    )
  end

  let(:image_file2) do
    Rack::Test::UploadedFile.new(
      StringIO.new("fake-image-data-2"),
      "image/jpeg",
      original_filename: "test2.jpg"
    )
  end

  let(:video_file) do
    Rack::Test::UploadedFile.new(
      StringIO.new("fake-video-data"),
      "video/mp4",
      original_filename: "video.mp4"
    )
  end

  let(:audio_file) do
    Rack::Test::UploadedFile.new(
      StringIO.new("fake-audio-data"),
      "audio/ogg",
      original_filename: "voice.ogg"
    )
  end

  let(:pdf_file) do
    Rack::Test::UploadedFile.new(
      StringIO.new("fake-pdf-data"),
      "application/pdf",
      original_filename: "document.pdf"
    )
  end

  around do |example|
    account.with_shard do
      example.run
    end
  end

  before do
    allow(Facebook::Messenger::Subscriptions).to receive_messages(subscribe: true, unsubscribe: true)
    allow(Messages::DeliveryWorker).to receive(:perform_async)
    allow(EventBroadcastWorker).to receive(:perform_async)
  end

  describe "validation and edge-case inputs" do
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it "returns an empty array when content and attachments are blank" do
      result = described_class.call(
        conversation: conversation,
        content: "",
        attachments: [],
        sender: user
      )
      expect(result).to eq([])
      expect(conversation.messages.count).to eq(0)
    end

    it "treats whitespace-only content as blank" do
      result = described_class.call(
        conversation: conversation,
        content: "   \n\t   ",
        attachments: nil,
        sender: user
      )
      expect(result).to eq([])
      expect(conversation.messages.count).to eq(0)
    end
  end

  describe "default/email channel (non-splitting)" do
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it "creates a single text-only message" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String))

      messages = described_class.call(
        conversation: conversation,
        content: "Hello from agent",
        sender: user
      )

      expect(messages.size).to eq(1)
      msg = messages.first
      expect(msg.content).to eq("Hello from agent")
      expect(msg.attachments).to be_empty
      expect(msg.sender).to eq(user)
      expect(msg.global?).to be(true)
    end

    it "creates a single unified message when text and multiple attachments are provided" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String)).once

      messages = described_class.call(
        conversation: conversation,
        content: "Here are the files",
        attachments: [image_file, pdf_file],
        sender: user
      )

      expect(messages.size).to eq(1)
      msg = messages.first
      expect(msg.content).to eq("Here are the files")
      expect(msg.attachments.count).to eq(2)
    end
  end

  describe "Facebook Page channel" do
    let(:channel) { create(:channel_facebook_page, account: account) }
    let(:inbox) { create(:inbox, account: account, channel: channel) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it "does not split text-only message" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String)).once

      messages = described_class.call(
        conversation: conversation,
        content: "Just text",
        sender: user
      )

      expect(messages.size).to eq(1)
      expect(messages.first.content).to eq("Just text")
      expect(messages.first.attachments).to be_empty
    end

    it "does not split single attachment without text" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String)).once

      messages = described_class.call(
        conversation: conversation,
        attachments: [image_file],
        sender: user
      )

      expect(messages.size).to eq(1)
      expect(messages.first.content).to be_nil
      expect(messages.first.attachments.count).to eq(1)
    end

    it "splits text + 1 attachment into 2 sibling messages" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, [kind_of(String), kind_of(String)]).once

      messages = described_class.call(
        conversation: conversation,
        content: "Check this screenshot",
        attachments: [image_file],
        sender: user
      )

      expect(messages.size).to eq(2)

      text_msg = messages.first
      expect(text_msg.content).to eq("Check this screenshot")
      expect(text_msg.attachments).to be_empty

      attachment_msg = messages.second
      expect(attachment_msg.content).to be_nil
      expect(attachment_msg.attachments.count).to eq(1)
      expect(attachment_msg.attachments.first.attachment_type).to eq("image")
    end

    it "splits text + 2 attachments into 3 sibling messages" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, [kind_of(String), kind_of(String), kind_of(String)]).once

      messages = described_class.call(
        conversation: conversation,
        content: "Two files for you",
        attachments: [image_file, pdf_file],
        sender: user
      )

      expect(messages.size).to eq(3)

      expect(messages[0].content).to eq("Two files for you")
      expect(messages[0].attachments).to be_empty

      expect(messages[1].content).to be_nil
      expect(messages[1].attachments.count).to eq(1)
      expect(messages[1].attachments.first.attachment_type).to eq("image")

      expect(messages[2].content).to be_nil
      expect(messages[2].attachments.count).to eq(1)
      expect(messages[2].attachments.first.attachment_type).to eq("file")
    end

    it "splits multiple attachments without text into individual sibling messages" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, [kind_of(String), kind_of(String)]).once

      messages = described_class.call(
        conversation: conversation,
        attachments: [image_file, image_file2],
        sender: user
      )

      expect(messages.size).to eq(2)
      expect(messages[0].content).to be_nil
      expect(messages[0].attachments.count).to eq(1)
      expect(messages[1].content).to be_nil
      expect(messages[1].attachments.count).to eq(1)
    end
  end

  describe "Instagram channel" do
    let(:channel) { create(:channel_instagram, account: account) }
    let(:inbox) { create(:inbox, account: account, channel: channel) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it "splits text + 1 attachment into 2 sibling messages" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, [kind_of(String), kind_of(String)]).once

      messages = described_class.call(
        conversation: conversation,
        content: "Look at this Instagram photo",
        attachments: [image_file],
        sender: user
      )

      expect(messages.size).to eq(2)
      expect(messages[0].content).to eq("Look at this Instagram photo")
      expect(messages[0].attachments).to be_empty
      expect(messages[1].content).to be_nil
      expect(messages[1].attachments.count).to eq(1)
    end
  end

  describe "WhatsApp Cloud API channel" do
    let(:channel) { create(:channel_whatsapp, account: account) }
    let(:inbox) { create(:inbox, account: account, channel: channel) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it "does not split text + 1 captionable image (keeps unified for WhatsApp caption)" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String)).once

      messages = described_class.call(
        conversation: conversation,
        content: "Photo with caption",
        attachments: [image_file],
        sender: user
      )

      expect(messages.size).to eq(1)
      msg = messages.first
      expect(msg.content).to eq("Photo with caption")
      expect(msg.attachments.count).to eq(1)
      expect(msg.attachments.first.attachment_type).to eq("image")
    end

    it "does not split text + 1 captionable PDF document" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String)).once

      messages = described_class.call(
        conversation: conversation,
        content: "Here is your invoice",
        attachments: [pdf_file],
        sender: user
      )

      expect(messages.size).to eq(1)
      msg = messages.first
      expect(msg.content).to eq("Here is your invoice")
      expect(msg.attachments.count).to eq(1)
      expect(msg.attachments.first.attachment_type).to eq("file")
    end

    it "does not split text + 1 captionable video" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String)).once

      messages = described_class.call(
        conversation: conversation,
        content: "Demo video",
        attachments: [video_file],
        sender: user
      )

      expect(messages.size).to eq(1)
      msg = messages.first
      expect(msg.content).to eq("Demo video")
      expect(msg.attachments.count).to eq(1)
      expect(msg.attachments.first.attachment_type).to eq("video")
    end

    it "splits text + 1 audio into separate text and audio messages (WhatsApp audio does not support captions)" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, [kind_of(String), kind_of(String)]).once

      messages = described_class.call(
        conversation: conversation,
        content: "Voice note message",
        attachments: [audio_file],
        sender: user
      )

      expect(messages.size).to eq(2)
      expect(messages[0].content).to eq("Voice note message")
      expect(messages[0].attachments).to be_empty

      expect(messages[1].content).to be_nil
      expect(messages[1].attachments.count).to eq(1)
      expect(messages[1].attachments.first.attachment_type).to eq("audio")
    end

    it "splits text + 2 images into captioned first image and sibling second image" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, [kind_of(String), kind_of(String)]).once

      messages = described_class.call(
        conversation: conversation,
        content: "Two photos for you",
        attachments: [image_file, image_file2],
        sender: user
      )

      expect(messages.size).to eq(2)

      primary_msg = messages[0]
      expect(primary_msg.content).to eq("Two photos for you")
      expect(primary_msg.attachments.count).to eq(1)
      expect(primary_msg.attachments.first.attachment_type).to eq("image")

      sibling_msg = messages[1]
      expect(sibling_msg.content).to be_nil
      expect(sibling_msg.attachments.count).to eq(1)
      expect(sibling_msg.attachments.first.attachment_type).to eq("image")
    end

    it "correctly pairs caption with captionable file when mixed with non-captionable audio" do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, [kind_of(String), kind_of(String)]).once

      messages = described_class.call(
        conversation: conversation,
        content: "Invoice audio note",
        attachments: [audio_file, pdf_file],
        sender: user
      )

      expect(messages.size).to eq(2)

      # PDF is captionable so it gets paired with the text
      captioned_msg = messages[0]
      expect(captioned_msg.content).to eq("Invoice audio note")
      expect(captioned_msg.attachments.first.attachment_type).to eq("file")

      # Audio note is sibling
      sibling_msg = messages[1]
      expect(sibling_msg.content).to be_nil
      expect(sibling_msg.attachments.first.attachment_type).to eq("audio")
    end
  end

  describe "personal visibility (internal notes)" do
    let(:channel) { create(:channel_facebook_page, account: account) }
    let(:inbox) { create(:inbox, account: account, channel: channel) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it "does NOT split personal notes even on Facebook channel with multiple attachments" do
      expect(Messages::DeliveryWorker).not_to receive(:perform_async)

      messages = described_class.call(
        conversation: conversation,
        content: "Internal team note with screenshots",
        attachments: [image_file, image_file2],
        sender: user,
        visibility: "personal"
      )

      expect(messages.size).to eq(1)
      note = messages.first
      expect(note.personal?).to be(true)
      expect(note.content).to eq("Internal team note with screenshots")
      expect(note.attachments.count).to eq(2)
    end
  end

  describe "database transaction atomicity and rollback" do
    let(:channel) { create(:channel_facebook_page, account: account) }
    let(:inbox) { create(:inbox, account: account, channel: channel) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it "rolls back all messages and enqueues zero delivery workers when an error occurs during splitting" do
      expect(Messages::DeliveryWorker).not_to receive(:perform_async)

      # Simulate a failure during attachment creation on the second message
      allow_any_instance_of(Message).to receive(:save!).and_wrap_original do |m, *args|
        if m.receiver.content.nil? # attachment message
          raise ActiveRecord::RecordInvalid
        else
          m.call(*args)
        end
      end

      expect {
        described_class.call(
          conversation: conversation,
          content: "Valid text",
          attachments: [image_file],
          sender: user
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      # Verify nothing was committed to the DB
      expect(conversation.messages.count).to eq(0)
    end
  end
end
