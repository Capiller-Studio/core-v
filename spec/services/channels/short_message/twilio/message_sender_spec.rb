require 'rails_helper'

RSpec.describe Channels::ShortMessage::Twilio::MessageSender do
  let(:customer) { double('Customer', full_phone_number: '+123456789') }
  let(:conversation) { double('Conversation', customer: customer) }
  let(:sender) { double('User', is_a?: true) }
  let(:channel) { double('Channel::ShortMessage', phone_number: '+987654321', configurations: { "account_sid" => "sid", "auth_token" => "token" }) }
  let(:inbox) { double('Inbox', channel: channel) }
  let(:message) { double('Message', content: 'Twilio msg', conversation: conversation, sender: sender, inbox: inbox) }
  let(:service) { described_class.new(message) }

  before do
    allow(sender).to receive(:is_a?).with(User).and_return(true)
  end

  describe '#call' do
    let(:twilio_client) { double('TwilioClient') }
    let(:messages_mock) { double('TwilioMessages') }
    let(:twilio_response) { double('TwilioResponse', sid: 'SM123') }

    before do
      stub_const('Twilio::REST::Client', double('ClientClass'))
      allow(Twilio::REST::Client).to receive(:new).with('sid', 'token').and_return(twilio_client)
      allow(twilio_client).to receive(:messages).and_return(messages_mock)
    end

    it 'sends SMS via Twilio SDK and updates message' do
      expect(messages_mock).to receive(:create).with(
        from: '+987654321',
        to: '+123456789',
        body: 'Twilio msg'
      ).and_return(twilio_response)

      expect(message).to receive(:update!).with(external_id: 'SM123', status: :delivered)

      service.call
    end

    it 'rescues TwilioError and marks message as failed' do
      stub_const('Twilio::REST::TwilioError', Class.new(StandardError))
      
      expect(messages_mock).to receive(:create).and_raise(Twilio::REST::TwilioError.new('Fail'))
      expect(message).to receive(:update!).with(status: :failed)
      expect(Rails.logger).to receive(:error).with(/Twilio SMS failed/)

      expect { service.call }.to raise_error(Twilio::REST::TwilioError)
    end
  end
end
