require 'rails_helper'

RSpec.describe Channels::ShortMessage::AwsSns::MessageSender do
  let(:customer) { double('Customer', full_phone_number: '+123456789') }
  let(:conversation) { double('Conversation', customer: customer) }
  let(:sender) { double('User', is_a?: true) }
  let(:channel) do 
    double('Channel::ShortMessage', 
      configurations: { "region" => "us-east-1", "access_key_id" => "key", "secret_access_key" => "secret" }
    ) 
  end
  let(:inbox) { double('Inbox', channel: channel) }
  let(:message) { double('Message', content: 'AWS msg', conversation: conversation, sender: sender, inbox: inbox) }
  let(:service) { described_class.new(message) }

  before do
    allow(sender).to receive(:is_a?).with(User).and_return(true)
  end

  describe '#call' do
    let(:aws_client) { double('AwsSnsClient') }
    let(:response) { double('Response', message_id: 'AWS123') }

    before do
      stub_const('Aws::SNS::Client', double('ClientClass'))
      allow(Aws::SNS::Client).to receive(:new).with(
        region: 'us-east-1',
        access_key_id: 'key',
        secret_access_key: 'secret'
      ).and_return(aws_client)
    end

    it 'publishes SMS via AWS SDK and updates message' do
      expect(aws_client).to receive(:publish).with(
        phone_number: '+123456789',
        message: 'AWS msg'
      ).and_return(response)

      expect(message).to receive(:update!).with(external_id: 'AWS123')

      service.call
    end

    it 'rescues AWS errors and logs them' do
      stub_const('Aws::SNS::Errors::ServiceError', Class.new(StandardError))
      
      expect(aws_client).to receive(:publish).and_raise(Aws::SNS::Errors::ServiceError.new('AWS Fail'))
      expect(Rails.logger).to receive(:error).with(/AWS SNS failed/)

      expect { service.call }.not_to raise_error
    end
  end
end
