require 'rails_helper'

RSpec.describe Channels::FacebookPages::MessageSender do
  let(:facebook_page_channel) { double('Channel::FacebookPage', page_identifier: 'page123') }
  let(:customer_inbox) { double('CustomerInbox', external_id: 'user123') }
  let(:attachments) { [] }
  let(:message) do
    double('Message',
           id: 1,
           content: 'Hello FB',
           attachments: attachments,
           data: {},
           external_id: nil,
           external_reply_to_id: nil,
           sender_type: nil,
           conversation: nil)
  end
  let(:service) { described_class.new(facebook_page_channel: facebook_page_channel, customer_inbox: customer_inbox, message: message) }

  before do
    stub_const('Facebook::Messenger::Bot', double('BotClass'))
    allow(Channels::MessageFormatter).to receive(:format_for_whatsapp_and_facebook) { |text| text }
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
      let(:message) do
        double('Message',
               id: 2,
               content: '',
               attachments: attachments,
               data: {},
               external_id: nil,
               external_reply_to_id: nil,
               sender_type: 'User',
               conversation: nil)
      end

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
        allow(err).to receive(:message).and_return("The session has been invalidated")
        expect(Facebook::Messenger::Bot).to receive(:deliver).and_raise(err)
        expect(message).to receive(:update!).with(hash_including(status: :failed))
        expect(facebook_page_channel).to receive(:authorization_error!)
        expect(Rails.logger).to receive(:error).with(/Facebook MessageSender error/)

        service.call
      end

      it 'handles json error responses' do
        expect(Facebook::Messenger::Bot).to receive(:deliver).and_return('{"error":{"message":"API error"}}')
        expect(message).to receive(:update!).with(hash_including(status: :failed))

        service.call
      end
    end

    context 'when outside 24 hour window' do
      let(:conversation) { double('Conversation') }
      let(:messages_relation) { double('MessagesRelation') }
      let(:ordered_relation) { double('OrderedRelation') }

      before do
        allow(message).to receive(:conversation).and_return(conversation)
        allow(conversation).to receive(:messages).and_return(messages_relation)
        allow(messages_relation).to receive(:where).with(sender_type: 'Customer').and_return(ordered_relation)
        allow(ordered_relation).to receive(:order).with(created_at: :desc).and_return(ordered_relation)
        allow(ordered_relation).to receive(:pick).with(:created_at).and_return(25.hours.ago)
      end

      it 'sends message with MESSAGE_TAG and ACCOUNT_UPDATE by default when sender is not a human User' do
        expected_params = {
          recipient: { id: 'user123' },
          message: { text: 'Hello FB' },
          messaging_type: 'MESSAGE_TAG',
          tag: 'ACCOUNT_UPDATE'
        }

        expect(Facebook::Messenger::Bot).to receive(:deliver).with(expected_params, page_id: 'page123').and_return('{"message_id":"msg_fb_tagged"}')
        expect(message).to receive(:update!).with(hash_including(external_id: 'msg_fb_tagged'))

        service.call
      end

      context 'with sender types and windows' do
        it 'uses HUMAN_AGENT tag for User sender within 7 days' do
          allow(message).to receive(:sender_type).and_return('User')

          expected_params = {
            recipient: { id: 'user123' },
            message: { text: 'Hello FB' },
            messaging_type: 'MESSAGE_TAG',
            tag: 'HUMAN_AGENT'
          }

          expect(Facebook::Messenger::Bot).to receive(:deliver).with(expected_params, page_id: 'page123').and_return('{"message_id":"msg_fb_human"}')
          expect(message).to receive(:update!).with(hash_including(external_id: 'msg_fb_human'))

          service.call
        end

        it 'falls back to ACCOUNT_UPDATE for AI bot sender' do
          allow(message).to receive(:sender_type).and_return('Ai::Agent')

          expected_params = {
            recipient: { id: 'user123' },
            message: { text: 'Hello FB' },
            messaging_type: 'MESSAGE_TAG',
            tag: 'ACCOUNT_UPDATE'
          }

          expect(Facebook::Messenger::Bot).to receive(:deliver).with(expected_params, page_id: 'page123').and_return('{"message_id":"msg_fb_ai"}')
          expect(message).to receive(:update!).with(hash_including(external_id: 'msg_fb_ai'))

          service.call
        end

        it 'falls back to ACCOUNT_UPDATE when outside 7 days' do
          allow(message).to receive(:sender_type).and_return('User')
          allow(ordered_relation).to receive(:pick).with(:created_at).and_return(8.days.ago)

          expected_params = {
            recipient: { id: 'user123' },
            message: { text: 'Hello FB' },
            messaging_type: 'MESSAGE_TAG',
            tag: 'ACCOUNT_UPDATE'
          }

          expect(Facebook::Messenger::Bot).to receive(:deliver).with(expected_params, page_id: 'page123').and_return('{"message_id":"msg_fb_old"}')
          expect(message).to receive(:update!).with(hash_including(external_id: 'msg_fb_old'))

          service.call
        end

        it 'falls back to ACCOUNT_UPDATE if HUMAN_AGENT fails with permission error (#230)' do
          allow(message).to receive(:sender_type).and_return('User')

          initial_params = {
            recipient: { id: 'user123' },
            message: { text: 'Hello FB' },
            messaging_type: 'MESSAGE_TAG',
            tag: 'HUMAN_AGENT'
          }

          fallback_params = {
            recipient: { id: 'user123' },
            message: { text: 'Hello FB' },
            messaging_type: 'MESSAGE_TAG',
            tag: 'ACCOUNT_UPDATE'
          }

          perm_error = Facebook::Messenger::FacebookError.allocate
          allow(perm_error).to receive(:message).and_return('(#230) Requires human_agent permission to manage the object.')

          expect(Facebook::Messenger::Bot).to receive(:deliver).with(initial_params, page_id: 'page123').and_raise(perm_error)
          expect(Facebook::Messenger::Bot).to receive(:deliver).with(fallback_params, page_id: 'page123').and_return('{"message_id":"msg_fb_perm_fallback"}')
          expect(message).to receive(:update!).with(hash_including(external_id: 'msg_fb_perm_fallback'))

          service.call
        end
      end
    end

    context 'when outside of allowed window error (#10) occurs' do
      it 'automatically retries with MESSAGE_TAG when FacebookError is raised' do
        initial_params = {
          recipient: { id: 'user123' },
          message: { text: 'Hello FB' },
          messaging_type: 'RESPONSE'
        }

        retry_params = {
          recipient: { id: 'user123' },
          message: { text: 'Hello FB' },
          messaging_type: 'MESSAGE_TAG',
          tag: 'ACCOUNT_UPDATE'
        }

        window_error = Facebook::Messenger::FacebookError.allocate
        allow(window_error).to receive(:message).and_return('(#10) This message is sent outside of allowed window.')

        expect(Facebook::Messenger::Bot).to receive(:deliver).with(initial_params, page_id: 'page123').and_raise(window_error)
        expect(Facebook::Messenger::Bot).to receive(:deliver).with(retry_params, page_id: 'page123').and_return('{"message_id":"msg_fb_retried"}')
        expect(message).to receive(:update!).with(hash_including(external_id: 'msg_fb_retried'))

        service.call
      end

      it 'automatically retries with MESSAGE_TAG when JSON error code 10 is returned' do
        initial_params = {
          recipient: { id: 'user123' },
          message: { text: 'Hello FB' },
          messaging_type: 'RESPONSE'
        }

        retry_params = {
          recipient: { id: 'user123' },
          message: { text: 'Hello FB' },
          messaging_type: 'MESSAGE_TAG',
          tag: 'ACCOUNT_UPDATE'
        }

        json_error = { error: { message: 'This message is sent outside of allowed window', code: 10 } }.to_json

        expect(Facebook::Messenger::Bot).to receive(:deliver).with(initial_params, page_id: 'page123').and_return(json_error)
        expect(Facebook::Messenger::Bot).to receive(:deliver).with(retry_params, page_id: 'page123').and_return('{"message_id":"msg_fb_retried_json"}')
        expect(message).to receive(:update!).with(hash_including(external_id: 'msg_fb_retried_json'))

        service.call
      end
    end

    context 'with missing recipient external_id' do
      let(:customer_inbox) { double('CustomerInbox', external_id: nil) }

      it 'marks message failed and does not attempt delivery' do
        expect(Facebook::Messenger::Bot).not_to receive(:deliver)
        expect(message).to receive(:update!).with(
          hash_including(
            status: :failed,
            data: hash_including("error_message" => "Recipient Facebook ID is missing")
          )
        )

        service.call
      end
    end

    context 'with attachment missing direct_download_url' do
      let(:attachment) { double('Attachment', attachment_type: 'image', direct_download_url: nil) }
      let(:attachments) { [attachment] }
      let(:message) do
        double('Message',
               id: 3,
               content: '',
               attachments: attachments,
               data: {},
               external_id: nil,
               external_reply_to_id: nil,
               sender_type: 'User',
               conversation: nil)
      end

      it 'skips delivery when download URL is blank' do
        expect(Facebook::Messenger::Bot).not_to receive(:deliver)
        service.call
      end
    end

    context 'with multiple attachments and parts' do
      let(:attachment1) { double('Attachment', attachment_type: 'image', direct_download_url: 'http://img1.url') }
      let(:attachment2) { double('Attachment', attachment_type: 'image', direct_download_url: 'http://img2.url') }
      let(:attachments) { [attachment1, attachment2] }
      let(:message) do
        double('Message',
               id: 99,
               content: 'Multiple FB parts',
               attachments: attachments,
               data: {},
               external_id: nil,
               external_reply_to_id: nil,
               sender_type: 'User',
               conversation: nil)
      end

      it 'updates external_id for each delivered message part' do
        expect(Facebook::Messenger::Bot).to receive(:deliver).and_return('{"message_id":"msg_part_1"}')
        expect(Facebook::Messenger::Bot).to receive(:deliver).and_return('{"message_id":"msg_part_2"}')
        expect(Facebook::Messenger::Bot).to receive(:deliver).and_return('{"message_id":"msg_part_3"}')

        expect(message).to receive(:update!).with(external_id: "msg_part_1")
        expect(message).to receive(:update!).with(external_id: "msg_part_2")
        expect(message).to receive(:update!).with(external_id: "msg_part_3")

        service.call
      end
    end

    context 'with OAuth token expiration (code 190)' do
      it 'triggers authorization_error! on facebook_page_channel' do
        json_error = { error: { message: 'Error validating access token: Session has expired', code: 190 } }.to_json
        expect(Facebook::Messenger::Bot).to receive(:deliver).and_return(json_error)
        expect(facebook_page_channel).to receive(:authorization_error!)
        expect(message).to receive(:update!).with(
          hash_including(
            status: :failed,
            data: hash_including("error_code" => 190)
          )
        )

        service.call
      end
    end

    context 'with transient network error' do
      it 're-raises Net::OpenTimeout so Sidekiq can retry' do
        expect(Facebook::Messenger::Bot).to receive(:deliver).and_raise(Net::OpenTimeout.new("Execution expired"))

        expect { service.call }.to raise_error(Net::OpenTimeout)
      end
    end
  end
end
