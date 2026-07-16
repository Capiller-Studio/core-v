require 'rails_helper'

RSpec.describe UnreadCounts::Reset do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  before do
    allow(UnreadCounts::Broadcast).to receive(:call)
    allow(RedisUtilities::Helpers).to receive(:hash_increment)
    allow(RedisUtilities::Helpers).to receive(:hash_get).and_return("5")
    allow(RedisUtilities::Helpers).to receive(:hash_delete)
    allow(RedisUtilities::Helpers).to receive(:hash_set)
    allow(RedisUtilities::Helpers).to receive(:set_remove)
    allow(RedisUtilities::Helpers).to receive(:set)
  end

  describe '#call' do
    context 'when resource is a Conversation' do
      let(:conversation) { create(:conversation, account: account) }
      let(:service) { described_class.new(conversation, user) }

      it 'resets conversation count and decrements inbox total' do
        service.call

        expect(RedisUtilities::Helpers).to have_received(:hash_delete)
          .with(instance_of(String), conversation.id)
        expect(RedisUtilities::Helpers).to have_received(:set_remove)
          .with(instance_of(String), conversation.id)
        expect(RedisUtilities::Helpers).to have_received(:hash_increment)
          .with(instance_of(String), conversation.inbox_id, -5)
          
        expect(UnreadCounts::Broadcast).to have_received(:call).with(member: user, account_id: account.id).at_least(:once)
      end
    end

    context 'when resource is a Mention' do
      let(:message) { create(:message, account: account) }
      let(:mention) { create(:mention, account: account, resource: message, mentioned: user) }
      let(:service) { described_class.new(mention, user) }

      it 'resets mention count to 0 and broadcasts' do
        service.call

        expect(RedisUtilities::Helpers).to have_received(:set).with(instance_of(String), 0).at_least(:once)
        expect(UnreadCounts::Broadcast).to have_received(:call).with(member: user, account_id: account.id).at_least(:once)
      end
    end
  end
end
