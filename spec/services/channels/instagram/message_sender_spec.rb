require 'rails_helper'

RSpec.describe Channels::Instagram::MessageSender do
  let(:instagram_channel) { double('Channel::Instagram', instagram_id: 'ig123', access_token: 'ig_token') }
  let(:customer_inbox) { double('CustomerInbox', external_id: 'user123') }
  let(:attachments) { [] }
  let(:message) do
    double('Message',
           id: 1,
           content: 'Hello IG',
           attachments: attachments,
           data: {},
           external_id: nil,
           external_reply_to_id: nil,
           sender_type: nil,
           conversation: nil)
  end
  let(:service) { described_class.new(instagram_channel: instagram_channel, customer_inbox: customer_inbox, message: message) }

  before do
    stub_const('Facebook::Messenger::Bot', double('BotClass'))
  end

  describe '#call' do
    let(:expected_url) { "https://graph.instagram.com/#{Channels::Instagram::OauthService::API_VERSION}/me/messages" }
    
    it 'delivers text message and updates status' do
      expected_params = {
        recipient: { id: 'user123' },
        message: { text: 'Hello IG' }
      }

      mock_response = instance_double(HTTParty::Response, success?: true, body: '{"message_id":"msg_ig_1"}')
      expect(HTTParty).to receive(:post).with(
        expected_url,
        headers: { "Content-Type" => "application/json" },
        query: { access_token: 'ig_token' },
        body: expected_params.to_json
      ).and_return(mock_response)
      
      expect(message).to receive(:update!).with(hash_including(external_id: 'msg_ig_1', status: :delivered))

      service.call
    end

    context 'when an error occurs' do
      it 'handles JSON response error and calls authorization_error if code 190' do
        mock_response = instance_double(HTTParty::Response, success?: false, body: '{"error":{"code": 190, "message": "Expired token"}}')
        expect(HTTParty).to receive(:post).and_return(mock_response)
        
        expect(message).to receive(:update!).with(hash_including(status: :failed))
        expect(instagram_channel).to receive(:authorization_error!)
        
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

      it 'attaches HUMAN_AGENT tag for User sender within 7 days' do
        allow(message).to receive(:sender_type).and_return('User')

        expected_params = {
          recipient: { id: 'user123' },
          message: { text: 'Hello IG' },
          tag: 'HUMAN_AGENT'
        }

        mock_response = instance_double(HTTParty::Response, success?: true, body: '{"message_id":"msg_ig_human"}')
        expect(HTTParty).to receive(:post).with(
          expected_url,
          headers: { "Content-Type" => "application/json" },
          query: { access_token: 'ig_token' },
          body: expected_params.to_json
        ).and_return(mock_response)

        expect(message).to receive(:update!).with(hash_including(external_id: 'msg_ig_human', status: :delivered))

        service.call
      end

      it 'does not attach tag for AI bot sender' do
        allow(message).to receive(:sender_type).and_return('Ai::Agent')

        expected_params = {
          recipient: { id: 'user123' },
          message: { text: 'Hello IG' }
        }

        mock_response = instance_double(HTTParty::Response, success?: true, body: '{"message_id":"msg_ig_ai"}')
        expect(HTTParty).to receive(:post).with(
          expected_url,
          headers: { "Content-Type" => "application/json" },
          query: { access_token: 'ig_token' },
          body: expected_params.to_json
        ).and_return(mock_response)

        expect(message).to receive(:update!).with(hash_including(external_id: 'msg_ig_ai', status: :delivered))

        service.call
      end

      it 'retries without tag if HUMAN_AGENT returns permission error code 230' do
        allow(message).to receive(:sender_type).and_return('User')

        initial_params = {
          recipient: { id: 'user123' },
          message: { text: 'Hello IG' },
          tag: 'HUMAN_AGENT'
        }

        retry_params = {
          recipient: { id: 'user123' },
          message: { text: 'Hello IG' }
        }

        error_response = instance_double(HTTParty::Response, success?: false, body: '{"error":{"code":230,"message":"Requires human_agent permission"}}')
        success_response = instance_double(HTTParty::Response, success?: true, body: '{"message_id":"msg_ig_retry"}')

        expect(HTTParty).to receive(:post).with(
          expected_url,
          headers: { "Content-Type" => "application/json" },
          query: { access_token: 'ig_token' },
          body: initial_params.to_json
        ).and_return(error_response)

        expect(HTTParty).to receive(:post).with(
          expected_url,
          headers: { "Content-Type" => "application/json" },
          query: { access_token: 'ig_token' },
          body: retry_params.to_json
        ).and_return(success_response)

        expect(message).to receive(:update!).with(hash_including(external_id: 'msg_ig_retry', status: :delivered))

        service.call
      end
    end

    context 'with missing recipient external_id' do
      let(:customer_inbox) { double('CustomerInbox', external_id: nil) }

      it 'marks message failed and does not call HTTParty' do
        expect(HTTParty).not_to receive(:post)
        expect(message).to receive(:update!).with(
          hash_including(
            status: :failed
          )
        )

        service.call
      end
    end

    context 'with attachments' do
      let(:attachment) { double('Attachment', attachment_type: 'image', direct_download_url: 'https://cdn.example.com/photo.jpg') }
      let(:attachments) { [attachment] }
      let(:message) do
        double('Message',
               id: 2,
               content: '',
               attachments: attachments,
               data: {},
               external_id: nil,
               external_reply_to_id: nil,
               sender_type: nil,
               conversation: nil)
      end

      it 'delivers attachment message with correct payload' do
        expected_attachment_params = {
          recipient: { id: 'user123' },
          message: {
            attachment: {
              type: 'image',
              payload: { url: 'https://cdn.example.com/photo.jpg' }
            }
          }
        }

        mock_response = instance_double(HTTParty::Response, success?: true, code: 200, body: '{"message_id":"msg_ig_att"}')
        expect(HTTParty).to receive(:post).with(
          expected_url,
          headers: { "Content-Type" => "application/json" },
          query: { access_token: 'ig_token' },
          body: expected_attachment_params.to_json
        ).and_return(mock_response)

        expect(message).to receive(:update!).with(hash_including(external_id: 'msg_ig_att', status: :delivered))

        service.call
      end

      it 'delivers audio attachment using AudioTranscoder' do
        audio_att = double('Attachment', attachment_type: 'audio', direct_download_url: 'https://cdn.example.com/audio.wav')
        allow(Channels::AudioTranscoder).to receive(:ensure_compatible_audio_url)
          .with(audio_att, channel_type: :instagram)
          .and_return('https://cdn.example.com/audio.m4a')

        msg = double('Message',
                     id: 25,
                     content: '',
                     attachments: [audio_att],
                     data: {},
                     external_id: nil,
                     external_reply_to_id: nil,
                     sender_type: nil,
                     conversation: nil)
        svc = described_class.new(instagram_channel: instagram_channel, customer_inbox: customer_inbox, message: msg)

        expected_audio_params = {
          recipient: { id: 'user123' },
          message: {
            attachment: {
              type: 'audio',
              payload: { url: 'https://cdn.example.com/audio.m4a' }
            }
          }
        }

        mock_response = instance_double(HTTParty::Response, success?: true, code: 200, body: '{"message_id":"msg_ig_audio"}')
        expect(HTTParty).to receive(:post).with(
          expected_url,
          headers: { "Content-Type" => "application/json" },
          query: { access_token: 'ig_token' },
          body: expected_audio_params.to_json
        ).and_return(mock_response)

        expect(msg).to receive(:update!).with(hash_including(external_id: 'msg_ig_audio', status: :delivered))

        svc.call
      end

      it 'keeps file attachment type as file even if file has audio-like name' do
        file_att = double('Attachment', attachment_type: 'file', direct_download_url: 'https://cdn.example.com/audio.mp3')
        msg = double('Message',
                     id: 26,
                     content: '',
                     attachments: [file_att],
                     data: {},
                     external_id: nil,
                     external_reply_to_id: nil,
                     sender_type: nil,
                     conversation: nil)
        svc = described_class.new(instagram_channel: instagram_channel, customer_inbox: customer_inbox, message: msg)

        expected_file_params = {
          recipient: { id: 'user123' },
          message: {
            attachment: {
              type: 'file',
              payload: { url: 'https://cdn.example.com/audio.mp3' }
            }
          }
        }

        mock_response = instance_double(HTTParty::Response, success?: true, code: 200, body: '{"message_id":"msg_ig_file"}')
        expect(HTTParty).to receive(:post).with(
          expected_url,
          headers: { "Content-Type" => "application/json" },
          query: { access_token: 'ig_token' },
          body: expected_file_params.to_json
        ).and_return(mock_response)

        expect(msg).to receive(:update!).with(hash_including(external_id: 'msg_ig_file', status: :delivered))

        svc.call
      end

      it 'skips attachment delivery when direct_download_url is blank' do
        allow(attachment).to receive(:direct_download_url).and_return(nil)
        expect(HTTParty).not_to receive(:post)

        service.call
      end
    end

    context 'with multiple attachments and parts' do
      let(:attachment1) { double('Attachment', attachment_type: 'image', direct_download_url: 'http://img1.url') }
      let(:attachment2) { double('Attachment', attachment_type: 'image', direct_download_url: 'http://img2.url') }
      let(:attachments) { [attachment1, attachment2] }
      let(:message) do
        double('Message',
               id: 42,
               content: 'Multiple IG parts',
               attachments: attachments,
               data: {},
               external_id: nil,
               external_reply_to_id: nil,
               sender_type: nil,
               conversation: nil)
      end

      it 'updates external_id and delivered status on each delivered part' do
        resp1 = instance_double(HTTParty::Response, success?: true, code: 200, body: '{"message_id":"ig_part_1"}')
        resp2 = instance_double(HTTParty::Response, success?: true, code: 200, body: '{"message_id":"ig_part_2"}')
        resp3 = instance_double(HTTParty::Response, success?: true, code: 200, body: '{"message_id":"ig_part_3"}')

        expect(HTTParty).to receive(:post).and_return(resp1, resp2, resp3)

        expect(message).to receive(:update!).with(external_id: "ig_part_1", status: :delivered)
        expect(message).to receive(:update!).with(external_id: "ig_part_2", status: :delivered)
        expect(message).to receive(:update!).with(external_id: "ig_part_3", status: :delivered)

        service.call
      end
    end

    context 'with transient error responses (429, 500, 502)' do
      it 'raises error for 429 rate limit to trigger Sidekiq retry' do
        mock_response = instance_double(HTTParty::Response,
          code: 429,
          success?: false,
          body: '{"error":{"code":4,"message":"Application request limit reached"}}'
        )
        expect(HTTParty).to receive(:post).and_return(mock_response)

        expect { service.call }.to raise_error(/Instagram API transient error \(429\)/)
      end

      it 'raises error for 500 server error to trigger Sidekiq retry' do
        mock_response = instance_double(HTTParty::Response,
          code: 500,
          success?: false,
          body: '{"error":{"code":2,"message":"Service temporarily unavailable"}}'
        )
        expect(HTTParty).to receive(:post).and_return(mock_response)

        expect { service.call }.to raise_error(/Instagram API transient error \(500\)/)
      end
    end

    context 'with transient network exception' do
      it 're-raises Net::ReadTimeout so Sidekiq can retry' do
        expect(HTTParty).to receive(:post).and_raise(Net::ReadTimeout.new("Read timeout"))

        expect { service.call }.to raise_error(Net::ReadTimeout)
      end

      it 're-raises Errno::ECONNRESET so Sidekiq can retry' do
        expect(HTTParty).to receive(:post).and_raise(Errno::ECONNRESET.new("Connection reset by peer"))

        expect { service.call }.to raise_error(Errno::ECONNRESET)
      end
    end
  end
end
