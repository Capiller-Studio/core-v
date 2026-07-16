require 'rails_helper'

RSpec.describe Channels::ShortMessage::Twilio::MessageCreator do
  let(:account) { double('Account') }
  let(:inbox) { double('Inbox') }
  let(:sender) { double('Customer') }
  let(:messages_assoc) { double('MessagesAssoc') }
  let(:conversation) { double('Conversation', messages: messages_assoc) }
  let(:short_message_channel) { double('Channel::ShortMessage') }

  let(:parsed_message) do
    { "MessageSid" => "SM123", "Body" => "Hello Twilio", "NumMedia" => "0" }
  end

  let(:service) do
    described_class.new(
      parsed_message: parsed_message, account: account, inbox: inbox, sender: sender, conversation: conversation, short_message_channel: short_message_channel
    )
  end

  before do
    allow(messages_assoc).to receive(:find_by).and_return(nil)
  end

  describe '#call' do
    it 'creates a message' do
      message_record = double('Message')
      expect(messages_assoc).to receive(:create!).with(
        hash_including(
          content: "Hello Twilio",
          external_id: "SM123"
        )
      ).and_return(message_record)

      expect(service.call).to eq(message_record)
    end

    context 'with media attachments' do
      let(:parsed_message) do
        {
          "MessageSid" => "SM123",
          "Body" => "Hello Twilio",
          "NumMedia" => "1",
          "MediaUrl0" => "http://media.url",
          "MediaContentType0" => "image/jpeg"
        }
      end

      it 'processes attachments using ActiveStorageDownloader' do
        message_record = double('Message', attachments: double('Attachments'))
        allow(messages_assoc).to receive(:create!).and_return(message_record)
        
        attachment_record = double('AttachmentRecord')
        expect(message_record.attachments).to receive(:create!).with(
          hash_including(remote_url: "http://media.url", attachment_type: :image)
        ).and_return(attachment_record)

        stub_const('Utilities::ActiveStorageDownloader', double('Downloader'))
        expect(Utilities::ActiveStorageDownloader).to receive(:attach).with(
          record: attachment_record,
          attachment_name: :file,
          url: "http://media.url"
        )

        service.call
      end
    end
  end
end
