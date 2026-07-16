require 'rails_helper'

RSpec.describe UnreadCounts::Sync do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(member: user, account_id: account.id) }

  before do
    allow(UnreadCounts::Broadcast).to receive(:call)
    allow(RedisUtilities::Helpers).to receive(:delete)
    allow(RedisUtilities::Helpers).to receive(:hash_set)
    allow(RedisUtilities::Helpers).to receive(:set_add)
    allow(RedisUtilities::Helpers).to receive(:hash_increment)
    allow(RedisUtilities::Helpers).to receive(:set)
  end

  describe '#call' do
    it 'clears existing counts and syncs from database' do
      conversation = create(:conversation, account: account)
      create(:conversation_member, conversation: conversation, member: user)
      # Create an unread message
      create(:message, account: account, conversation: conversation)
      
      create(:mention, account: account, mentioned: user)

      service.call

      # Verify clears
      expect(RedisUtilities::Helpers).to have_received(:delete).exactly(3).times
      
      # Verify conversation sync
      expect(RedisUtilities::Helpers).to have_received(:hash_set).with(instance_of(String), conversation.id, 1).at_least(:once)
      expect(RedisUtilities::Helpers).to have_received(:set_add).with(instance_of(String), conversation.id).at_least(:once)
      expect(RedisUtilities::Helpers).to have_received(:hash_increment).with(instance_of(String), conversation.inbox_id, 1).at_least(:once)
      
      # Verify mention sync
      expect(RedisUtilities::Helpers).to have_received(:set).with(instance_of(String), 1).at_least(:once)

      expect(UnreadCounts::Broadcast).to have_received(:call).with(member: user, account_id: account.id).at_least(:once)
    end
  end
end
