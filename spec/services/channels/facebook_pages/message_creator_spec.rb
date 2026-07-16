require 'rails_helper'

RSpec.describe Channels::FacebookPages::MessageCreator do
  let(:account) { double('Account') }
  let(:inbox) { double('Inbox') }
  let(:sender) { double('Customer') }
  let(:conversation) { double('Conversation', messages: messages_assoc) }
  let(:messages_assoc) { double('MessagesAssoc') }
  let(:facebook_page_channel) { double('FacebookPageChannel', access_token: 'token') }
  
  let(:parsed_message) do 
    double('ParsedMessage', 
      mid: 'fb_mid_123', 
      reply_to_mid: 'fb_mid_0', 
      content: 'Hello',
      attachments: attachments
    ) 
  end
  let(:attachments) { [] }
  
  let(:service) do
    described_class.new(
      parsed_message: parsed_message, 
      account: account, 
      inbox: inbox, 
      sender: sender, 
      conversation: conversation,
      facebook_page_channel: facebook_page_channel
    )
  end

  before do
    allow(messages_assoc).to receive(:find_by).with(external_id: 'fb_mid_123').and_return(nil)
  end

  describe '#call' do
    it 'creates a message if it does not exist' do
      message = double('Message', attachments: [])
      expect(messages_assoc).to receive(:create!).with(
        hash_including(
          account: account,
          sender: sender,
          content: 'Hello',
          inbox: inbox,
          external_id: 'fb_mid_123',
          external_reply_to_id: 'fb_mid_0'
        )
      ).and_return(message)

      expect(service.call).to eq(message)
    end

    it 'returns existing message if it exists' do
      existing_message = double('Message')
      allow(messages_assoc).to receive(:find_by).with(external_id: 'fb_mid_123').and_return(existing_message)
      
      expect(messages_assoc).not_to receive(:create!)
      expect(service.call).to eq(existing_message)
    end

    context 'with attachments' do
      let(:attachments) { [{ "type" => "image", "payload" => { "url" => "http://test.com/img.png" } }] }
      let(:message) { double('Message', attachments: message_attachments_assoc) }
      let(:message_attachments_assoc) { double('MessageAttachmentsAssoc') }
      let(:tempfile) { double('Tempfile', original_filename: 'img.png', content_type: 'image/png') }
      let(:attachment_record) { double('AttachmentRecord', remote_url: "http://test.com/img.png", attachment_type: 'image', file: active_storage_file) }
      let(:active_storage_file) { double('ActiveStorageFile') }

      before do
        stub_const('Down', double('Down'))
        allow(Down).to receive(:download).with("http://test.com/img.png").and_return(tempfile)
        allow(messages_assoc).to receive(:create!).and_return(message)
        
        stub_const('Utilities::AttachmentTypeHelpers', double('Helpers'))
        allow(Utilities::AttachmentTypeHelpers).to receive(:attachment_type).and_return('image')
      end

      it 'downloads and processes file attachments' do
        expect(message_attachments_assoc).to receive(:create!).with(
          hash_including(remote_url: "http://test.com/img.png", attachment_type: 'image')
        ).and_return(attachment_record)

        expect(active_storage_file).to receive(:attach).with(
          hash_including(io: tempfile, filename: 'img.png', content_type: 'image/png')
        )

        service.call
      end
    end
  end
end
