require 'rails_helper'

RSpec.describe Inboxes::InboxCreator do
  let(:account) { create(:account) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end
  
  describe '#call' do
    context 'when inbox_type is Email' do
      let(:channel) { create(:channel_email, account: account) }
      let(:params) { { name: 'Support Email', channel_id: channel.id, channel_type: 'Channel::Email' } }
      let(:service) { described_class.new(inbox_type: 'Email', inbox_params: params, current_account: account) }

      it 'creates an email inbox' do
        expect(Inbox).to receive(:create!).with(
          name: 'Support Email',
          account: account,
          primary_inbox: true,
          channel: channel
        )
        Current.set(account: account) { service.call }
      end
    end

    context 'when inbox_type is FacebookPage' do
      before do
        allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks).and_return(true)
      end

      let(:channel) { create(:channel_facebook_page, account: account) }
      let(:params) { { name: 'FB Support', channel_id: channel.id, channel_type: 'Channel::FacebookPage' } }
      let(:service) { described_class.new(inbox_type: 'FacebookPage', inbox_params: params, current_account: account) }

      it 'creates a facebook page inbox' do
        expect(Inbox).to receive(:create!).with(
          name: 'FB Support',
          account: account,
          primary_inbox: true,
          channel: channel
        )
        Current.set(account: account) { service.call }
      end
    end

    context 'when inbox_type is nil' do
      let(:service) { described_class.new(inbox_type: nil, inbox_params: {}, current_account: account) }

      it 'does not create an inbox' do
        expect { service.call }.not_to change(Inbox, :count)
      end
    end
  end
end
