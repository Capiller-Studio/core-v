require 'rails_helper'

RSpec.describe Channels::FacebookPages::MessageSender do
  let(:facebook_page_channel) { double('Channel::FacebookPage', page_identifier: 'page123') }
  let(:customer_inbox) { double('CustomerInbox', external_id: 'user123') }
  let(:attachments) { [] }
  let(:message) { double('Message', content: 'Hello FB', attachments: attachments) }
  let(:service) { described_class.new(facebook_page_channel: facebook_page_channel, customer_inbox: customer_inbox, message: message) }

  before do
    stub_const('Facebook::Messenger::Bot', double('BotClass'))
    allow(Channels::MessageFormatter).to receive(:format_for_whatsapp_and_facebook).with('Hello FB').and_return('Hello FB')
  end

  describe '#call' do
    it 'delivers text message and updates external_id' do
      expected_params = {
        recipient: { id: 'user123' },
        message: { text: 'Hello FB' },
        messaging_type: "RESPONSE"
      }

      expect(Facebook::Messenger::Bot).to receive(:deliver).with(expected_params, page_id: 'page123').and_return('{"message_id":"msg_fb_1"}')
      expect(message).to receive(:update!).with(external_id: 'msg_fb_1')

      service.call
    end

    context 'with attachments' do
      let(:attachment) { double('Attachment', attachment_type: 'image', direct_download_url: 'http://img.url') }
      let(:attachments) { [attachment] }
      let(:message) { double('Message', content: '', attachments: attachments) }

      it 'delivers attachment messages' do
        expected_params = {
          recipient: { id: 'user123' },
          message: {
            attachment: {
              type: 'image',
              payload: { url: 'http://img.url' }
            }
          },
          messaging_type: "RESPONSE"
        }

        expect(Facebook::Messenger::Bot).to receive(:deliver).with(expected_params, page_id: 'page123').and_return('{"message_id":"msg_fb_2"}')
        expect(message).to receive(:update!).with(external_id: 'msg_fb_2')

        service.call
      end
    end

    context 'when an error occurs' do
      it 'logs error and updates message status to failed' do
        err = Facebook::Messenger::FacebookError.allocate
        allow(err).to receive(:to_s).and_return("The session has been invalidated")
        expect(Facebook::Messenger::Bot).to receive(:deliver).and_raise(err)
        expect(message).to receive(:update!).with(status: :failed)
        expect(facebook_page_channel).to receive(:authorization_error!)
        expect(Rails.logger).to receive(:error).with(/Facebook MessageSender error/)

        service.call
      end

      it 'handles json error responses' do
        expect(Facebook::Messenger::Bot).to receive(:deliver).and_return('{"error":{"message":"API error"}}')
        expect(message).to receive(:update!).with(status: :failed)

        service.call
      end
    end
  end
end
