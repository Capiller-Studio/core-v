require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::MessageCreator do
  let(:account) { double('Account') }
  let(:inbox) { double('Inbox') }
  let(:sender) { double('Customer') }
  let(:messages_assoc) { double('MessagesAssoc') }
  let(:conversation) { double('Conversation', messages: messages_assoc) }
  let(:whatsapp_channel) { double('Channel::Whatsapp', graph_api_url: 'http://api.wa/media/1', api_headers: {}) }

  let(:parsed_message) do
    { messages: [ message_params ] }
  end

  let(:message_params) do
    { id: "msg_wa_1", type: "text", text: { body: "WA text" } }
  end
  
  let(:service) do
    described_class.new(
      parsed_message: parsed_message,
      account: account,
      inbox: inbox,
      sender: sender,
      conversation: conversation,
      whatsapp_channel: whatsapp_channel,
      message_type: "text"
    )
  end

  before do
    allow(messages_assoc).to receive(:find_by).and_return(nil)
    allow(Channels::MessageFormatter).to receive(:parse_whatsapp_markdown_to_html).and_return("WA text HTML")
  end

  describe '#call' do
    it 'creates text message' do
      message_record = double('Message')
      expect(messages_assoc).to receive(:build).with(
        hash_including(content: "WA text HTML", external_id: "msg_wa_1")
      ).and_return(message_record)
      expect(message_record).to receive(:save!)

      service.call
    end

    context 'with image attachment' do
      let(:message_params) do
        { id: "msg_wa_2", type: "image", image: { id: "media_1", caption: "Look at this" } }
      end

      let(:service) do
        described_class.new(
          parsed_message: parsed_message, account: account, inbox: inbox, sender: sender, conversation: conversation,
          whatsapp_channel: whatsapp_channel, message_type: "image"
        )
      end

      it 'downloads attachment and saves message' do
        message_record = double('Message', 'content=': nil, content: nil, attachments: double('Attachments'))
        allow(messages_assoc).to receive(:build).and_return(message_record)
        
        response = double('Response', unauthorized?: false, success?: true, parsed_response: { "url" => "http://media.url" })
        expect(HTTParty).to receive(:get).with("http://api.wa/media/1", headers: {}).and_return(response)
        
        tempfile = double('Tempfile', original_filename: 'img.jpg', content_type: 'image/jpeg')
        stub_const('Down', double('Down'))
        expect(Down).to receive(:download).with("http://media.url", headers: {}).and_return(tempfile)

        expect(message_record.attachments).to receive(:new).with(
          hash_including(attachment_type: :image)
        )
        expect(message_record).to receive(:save!)

        service.call
      end
    end
  end
end
