require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::MessageSender do
  let(:whatsapp_channel) { double('Channel::Whatsapp', phone_number_endpoint: 'https://api.whatsapp/123', api_headers: {}, full_phone_number: '+123') }
  let(:customer) { double('Customer', full_phone_number: '+987') }
  let(:customer_inbox) { double('CustomerInbox', customer: customer) }
  let(:message) { double('Message', content: 'Hello', attachments: [], external_reply_to_id: nil) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel, customer_inbox: customer_inbox, message: message) }

  before do
    allow(Channels::MessageFormatter).to receive(:format_for_whatsapp_and_facebook).with('Hello').and_return('Hello Markdown')
  end

  describe '#call' do
    it 'sends text message via HTTParty' do
      response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_msg_1" }] })
      
      expected_body = {
        messaging_product: "whatsapp",
        context: nil,
        to: '+987',
        text: { body: 'Hello Markdown' },
        type: "text"
      }.to_json

      expect(HTTParty).to receive(:post).with(
        "https://api.whatsapp/123/messages",
        headers: {},
        body: expected_body
      ).and_return(response)

      expect(message).to receive(:update!).with(external_id: "wa_msg_1")

      service.call
    end

    context 'with attachments' do
      let(:file) { double('File', filename: 'doc.pdf') }
      let(:attachment) { double('Attachment', attachment_type: 'document', direct_download_url: 'http://doc.url', file: file) }
      let(:message) { double('Message', content: 'Here is doc', attachments: [attachment], external_reply_to_id: 'wa_parent_1') }

      it 'sends attachment message' do
        response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_msg_2" }] })
        
        allow(Channels::MessageFormatter).to receive(:format_for_whatsapp_and_facebook).with('Here is doc').and_return('Here is doc')

        expected_body = {
          messaging_product: "whatsapp",
          context: { message_id: 'wa_parent_1' },
          to: '+987',
          type: "document",
          "document" => { link: 'http://doc.url', "caption" => 'Here is doc', "filename" => 'doc.pdf' }
        }.to_json

        expect(HTTParty).to receive(:post).with(
          "https://api.whatsapp/123/messages",
          headers: {},
          body: expected_body
        ).and_return(response)

        expect(message).to receive(:update!).with(external_id: "wa_msg_2")

        service.call
      end
    end
  end
end
