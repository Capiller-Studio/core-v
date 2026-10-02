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

  describe "#detect_attachment_type" do
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let(:creator) { described_class.new(conversation: conversation, sender: user) }

    it "returns the existing attachment_type if file is an Attachment" do
      att = double("Attachment", is_a?: true, attachment_type: "audio")
      expect(creator.send(:detect_attachment_type, att)).to eq("audio")
    end

    it "detects image MIME type as :image" do
      file = double("Upload", is_a?: false, content_type: "image/jpeg", original_filename: "photo.jpg")
      expect(creator.send(:detect_attachment_type, file)).to eq(:image)
    end

    it "detects video MIME type as :video" do
      file = double("Upload", is_a?: false, content_type: "video/mp4", original_filename: "movie.mp4")
      expect(creator.send(:detect_attachment_type, file)).to eq(:video)
    end

    it "detects audio MIME type as :audio" do
      file = double("Upload", is_a?: false, content_type: "audio/webm", original_filename: "voice.webm")
      expect(creator.send(:detect_attachment_type, file)).to eq(:audio)
    end

    it "detects audio by extension when content_type is application/octet-stream" do
      %w[.wav .mp3 .m4a .ogg .aac .opus].each do |ext|
        file = double("Upload", is_a?: false, content_type: "application/octet-stream", original_filename: "voice#{ext}")
        expect(creator.send(:detect_attachment_type, file)).to eq(:audio)
      end
    end

    it "detects video by extension when content_type is blank" do
      file = double("Upload", is_a?: false, content_type: "", original_filename: "clip.mp4")
      expect(creator.send(:detect_attachment_type, file)).to eq(:video)
    end

    it "detects image by extension when content_type is application/octet-stream" do
      file = double("Upload", is_a?: false, content_type: "application/octet-stream", original_filename: "photo.png")
      expect(creator.send(:detect_attachment_type, file)).to eq(:image)
    end

    it "defaults to :file for general documents and unknown extensions" do
      %w[.pdf .zip .docx .txt .tar.gz].each do |ext|
        file = double("Upload", is_a?: false, content_type: "application/octet-stream", original_filename: "doc#{ext}")
        expect(creator.send(:detect_attachment_type, file)).to eq(:file)
      end
    end

    it "detects uppercase audio extensions (.WAV, .MP3, .OGG)" do
      %w[.WAV .MP3 .OGG .M4A .AAC .OPUS].each do |ext|
        file = double("Upload", is_a?: false, content_type: "application/octet-stream", original_filename: "VOICE#{ext}")
        expect(creator.send(:detect_attachment_type, file)).to eq(:audio)
      end
    end

    it "detects uppercase image extensions (.PNG, .JPG, .JPEG, .WEBP)" do
      %w[.PNG .JPG .JPEG .GIF .WEBP].each do |ext|
        file = double("Upload", is_a?: false, content_type: "application/octet-stream", original_filename: "PHOTO#{ext}")
        expect(creator.send(:detect_attachment_type, file)).to eq(:image)
      end
    end

    it "detects attachment type from ActiveStorage Blob objects responding to filename and content_type" do
      blob_audio = double("Blob", is_a?: false, content_type: "audio/ogg", filename: double(to_s: "recording.ogg"))
      expect(creator.send(:detect_attachment_type, blob_audio)).to eq(:audio)

      blob_image = double("Blob", is_a?: false, content_type: "image/png", filename: double(to_s: "screenshot.png"))
      expect(creator.send(:detect_attachment_type, blob_image)).to eq(:image)
    end

    it "falls back to attached file blob when Attachment attachment_type is blank" do
      dummy_att = build(:attachment, account: account)
      dummy_att.attachment_type = nil
      dummy_att.file.attach(io: StringIO.new("fake-audio"), filename: "recording.mp3", content_type: "audio/mpeg")

      expect(creator.send(:detect_attachment_type, dummy_att)).to eq(:audio)
    end

    it "safely handles StringIO uploads where path is undefined or raises" do
      string_io_file = Rack::Test::UploadedFile.new(
        StringIO.new("audio content"),
        "audio/wav",
        original_filename: "voice.wav"
      )
      expect(creator.send(:detect_attachment_type, string_io_file)).to eq(:audio)
    end
  end

  describe "#captionable_attachment?" do
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let(:creator) { described_class.new(conversation: conversation, sender: user) }

    it "returns true for image, video, and file attachments" do
      expect(creator.send(:captionable_attachment?, image_file)).to be true
      expect(creator.send(:captionable_attachment?, video_file)).to be true
      expect(creator.send(:captionable_attachment?, pdf_file)).to be true
    end

    it "returns false for audio attachments" do
      expect(creator.send(:captionable_attachment?, audio_file)).to be false
    end

    it "checks attachment_type when given an Attachment record" do
      audio_att = build(:attachment, account: account, attachment_type: :audio)
      image_att = build(:attachment, account: account, attachment_type: :image)
      file_att = build(:attachment, account: account, attachment_type: :file)

      expect(creator.send(:captionable_attachment?, audio_att)).to be false
      expect(creator.send(:captionable_attachment?, image_att)).to be true
      expect(creator.send(:captionable_attachment?, file_att)).to be true
    end
  end

  describe "existing Attachment records" do
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it "reassigns resource on existing Attachment record to the newly created message" do
      old_message = create(:message, account: account, conversation: conversation)
      attachment_record = create(:attachment, account: account, resource: old_message, attachment_type: :audio)
      expect(attachment_record.resource).to eq(old_message)

      messages = described_class.call(
        conversation: conversation,
        content: "Here is your audio",
        attachments: [attachment_record],
        sender: user
      )

      expect(messages.size).to eq(1)
      expect(attachment_record.reload.resource).to eq(messages.first)
      expect(attachment_record.resource).not_to eq(old_message)
      expect(attachment_record.attachment_type).to eq("audio")
    end
  end

  describe "WebWidget channel handling" do
    let(:channel) { create(:channel_web_widget, account: account) }
    let(:inbox) { create(:inbox, account: account, channel: channel) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it "creates a single message with multiple mixed attachments and sets attachment types correctly" do
      messages = described_class.call(
        conversation: conversation,
        content: "Mixed media message",
        attachments: [audio_file, image_file, pdf_file],
        sender: user
      )

      expect(messages.size).to eq(1)
      msg = messages.first
      expect(msg.content).to eq("Mixed media message")
      expect(msg.attachments.count).to eq(3)

      types = msg.attachments.map(&:attachment_type)
      expect(types).to contain_exactly("audio", "image", "file")
    end
  end
end
