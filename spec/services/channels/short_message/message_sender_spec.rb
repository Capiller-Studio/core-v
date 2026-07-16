require 'rails_helper'

RSpec.describe Channels::ShortMessage::MessageSender do
  let(:channel) { double('Channel::ShortMessage', service: provider) }
  let(:message) { double('Message', content: 'hello') }
  let(:service) { described_class.new(short_message_channel: channel, message: message) }

  before do
    stub_const('Channels::ShortMessage::Twilio::MessageSender', double('TwilioSender'))
    stub_const('Channels::ShortMessage::Signalwire::MessageSender', double('SignalwireSender'))
    stub_const('Channels::ShortMessage::AwsSns::MessageSender', double('AwsSnsSender'))
  end

  describe '#call' do
    context 'with twilio provider' do
      let(:provider) { 'twilio' }

      it 'calls Twilio MessageSender' do
        expect(Channels::ShortMessage::Twilio::MessageSender).to receive(:call).with(message)
        service.call
      end
    end

    context 'with signalwire provider' do
      let(:provider) { 'signalwire' }

      it 'calls Signalwire MessageSender' do
        expect(Channels::ShortMessage::Signalwire::MessageSender).to receive(:call).with(message)
        service.call
      end
    end

    context 'with aws_sns provider' do
      let(:provider) { 'aws_sns' }

      it 'calls AwsSns MessageSender' do
        expect(Channels::ShortMessage::AwsSns::MessageSender).to receive(:call).with(message)
        service.call
      end
    end

    context 'with unsupported provider' do
      let(:provider) { 'unknown' }

      it 'does not call any sender and logs a warning' do
        expect(Rails.logger).to receive(:warn).with(/Unsupported provider/)
        service.call
      end
    end

    context 'when message content is blank' do
      let(:provider) { 'twilio' }
      let(:message) { double('Message', content: '') }

      it 'returns early' do
        expect(Channels::ShortMessage::Twilio::MessageSender).not_to receive(:call)
        service.call
      end
    end
  end
end
