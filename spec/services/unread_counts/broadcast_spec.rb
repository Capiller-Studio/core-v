require 'rails_helper'

RSpec.describe UnreadCounts::Broadcast do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:customer) { create(:customer, account: account) }

  describe '#call' do
    before do
      allow(UnreadCounts::Current).to receive(:call).and_return({
        conversations: { "1" => "2" },
        mentions: 5,
        inboxes: { "2" => "1" },
        unread_conversation_ids: ["1"]
      })
      allow(EventBroadcastWorker).to receive(:perform_async)
    end

    context 'when member is a User' do
      let(:service) { described_class.new(member: user, account_id: account.id) }

      it 'broadcasts to the user connection token' do
        user.update!(connection_token: 'user-token-123')
        service.call

        expect(UnreadCounts::Current).to have_received(:call).with(member: user, account_id: account.id)
        expect(EventBroadcastWorker).to have_received(:perform_async).with(
          { conversations: { "1" => "2" }, mentions: 5, inboxes: { "2" => "1" }, unread_conversation_ids: ["1"] }.to_json,
          "unread_counts.updated",
          ['user-token-123'],
          account.id
        )
      end
    end

    context 'when member is a Customer' do
      let(:service) { described_class.new(member: customer, account_id: account.id) }

      it 'broadcasts to all customer inbox connection tokens' do
        allow(customer).to receive_message_chain(:customer_inboxes, :pluck).and_return(['customer-token-456'])
        
        service.call

        expect(UnreadCounts::Current).to have_received(:call).with(member: customer, account_id: account.id)
        expect(EventBroadcastWorker).to have_received(:perform_async).with(
          { conversations: { "1" => "2" }, mentions: 5, inboxes: { "2" => "1" }, unread_conversation_ids: ["1"] }.to_json,
          "unread_counts.updated",
          ['customer-token-456'],
          account.id
        )
      end
    end

    context 'when member has no connection tokens' do
      let(:service) { described_class.new(member: user, account_id: account.id) }

      it 'does not broadcast' do
        allow(user).to receive(:connection_token).and_return(nil)
        expect(UnreadCounts::Current).not_to receive(:call)
        expect(EventBroadcastWorker).not_to receive(:perform_async).with(
          anything,
          "unread_counts.updated",
          anything,
          anything
        )

        service.call
      end
    end
  end
end
