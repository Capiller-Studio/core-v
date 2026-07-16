require 'rails_helper'

RSpec.describe Channels::ShortMessage::Signalwire::MessageSender do
  let(:customer) { double('Customer', full_phone_number: '+123456789') }
  let(:conversation) { double('Conversation', customer: customer) }
  let(:sender) { double('User', is_a?: true) }
  let(:channel) do 
    double('Channel::ShortMessage', 
      phone_number: '+987654321', 
      configurations: { "project" => "proj", "token" => "tok", "space_url" => "http://space.url" }
    ) 
  end
  let(:inbox) { double('Inbox', channel: channel) }
  let(:message) { double('Message', content: 'Signalwire msg', conversation: conversation, sender: sender, inbox: inbox) }
  let(:service) { described_class.new(message) }

  before do
    allow(sender).to receive(:is_a?).with(User).and_return(true)
  end

  describe '#call' do
    let(:signalwire_client) { double('SignalwireClient') }
    let(:messages_mock) { double('SignalwireMessages') }
    let(:response) { double('Response', sid: 'SW123') }

    before do
      stub_const('Signalwire::REST::Client', double('ClientClass'))
      allow(Signalwire::REST::Client).to receive(:new).with('proj', 'tok', signalwire_space_url: 'http://space.url').and_return(signalwire_client)
      allow(signalwire_client).to receive(:messages).and_return(messages_mock)
    end

    it 'sends SMS via Signalwire SDK and updates message' do
      expect(messages_mock).to receive(:create).with(
        from: '+987654321',
        to: '+123456789',
        body: 'Signalwire msg'
      ).and_return(response)

      expect(message).to receive(:update!).with(external_id: 'SW123')

      service.call
    end

    it 'rescues StandardError and logs error' do
      expect(messages_mock).to receive(:create).and_raise(StandardError.new('Fail SW'))
      expect(Rails.logger).to receive(:error).with(/Signalwire SMS failed/)

      expect { service.call }.not_to raise_error
    end
  end
end
