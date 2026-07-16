require 'rails_helper'

RSpec.describe Channels::ChannelCreator do
  let(:account) { double('Account') }
  let(:inboxes_assoc) { double('InboxesAssoc') }

  before do
    allow(account).to receive(:with_shard).and_yield
    allow(ShardRecord).to receive(:transaction).and_yield
  end

  describe '#call' do
    context 'creating an email channel' do
      let(:channel_params) do
        {
          name: 'Support Email',
          email: 'support@example.com',
          primary_inbox_attributes: { greeting: 'Hi' }
        }
      end
      let(:service) { described_class.new(channel_type: 'email', channel_params: channel_params, current_account: account) }
      let(:channel) { double('Channel::Email', 'account=': nil) }



      it 'creates the channel and inbox' do
        expect(Channel::Email).to receive(:new).with({ email: 'support@example.com', name: 'Support Email' }).and_return(channel)
        expect(channel).to receive(:save!)
        expect(channel).to receive(:inboxes).and_return(inboxes_assoc)
        
        expect(inboxes_assoc).to receive(:create!).with(
          hash_including(
            name: 'Support Email',
            account: account,
            primary_inbox: true,
            greeting: 'Hi'
          )
        )

        expect(service.call).to be true
      end
    end

    context 'creating a web widget channel' do
      let(:channel_params) do
        {
          name: 'Chat Widget',
          anonymous_allowed: 'true',
          primary_inbox_attributes: { greeting: 'Chat with us' }
        }
      end
      let(:service) { described_class.new(channel_type: 'web_widget', channel_params: channel_params, current_account: account) }
      let(:channel) { double('Channel::WebWidget', 'account=': nil, 'anonymous_allowed=': nil, 'help_center_enabled=': nil, 'pre_chat_form_enabled=': nil, 'secure_identity_enforced=': nil, 'custom_branding=': nil) }



      it 'creates the channel and sets booleans' do
        expect(Channel::WebWidget).to receive(:new).with({ name: 'Chat Widget' }).and_return(channel)
        
        expect(channel).to receive(:anonymous_allowed=).with(true)
        expect(channel).to receive(:help_center_enabled=).with(false)
        expect(channel).to receive(:save!)
        expect(channel).to receive(:inboxes).and_return(inboxes_assoc)
        
        expect(inboxes_assoc).to receive(:create!).with(
          hash_including(
            name: 'Chat Widget',
            account: account,
            primary_inbox: true,
            greeting: 'Chat with us'
          )
        )

        expect(service.call).to be true
      end
    end

    context 'handling errors' do
      let(:service) { described_class.new(channel_type: 'email', channel_params: {}, current_account: account) }
      
      it 'rescues RecordInvalid and returns false' do
        channel = double('Channel')
        allow(Channel::Email).to receive(:new).and_return(channel)
        allow(channel).to receive(:account=)
        allow(channel).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved.new("Error"))

        expect(Rails.logger).to receive(:error).with(/ChannelCreator Validation Failed/)
        expect(service.call).to be false
      end
    end
  end
end
