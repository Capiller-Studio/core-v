require 'rails_helper'

RSpec.describe UnreadCounts::Current do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(member: user, account_id: account.id) }

  describe '#call' do
    before do
      # Mock RedisUtilities::Helpers
      allow(RedisUtilities::Helpers).to receive(:hash_get_all).and_return({})
      allow(RedisUtilities::Helpers).to receive(:get).and_return(0)
      allow(RedisUtilities::Helpers).to receive(:set_members).and_return([])

      # Stub specific returns
      allow(RedisUtilities::Helpers).to receive(:hash_get_all)
        .with(RedisUtilities::Keys::UNREAD_CONVERSATION_COUNT % { account_id: account.id, member_id: user.id })
        .and_return({ "1" => "2" })
        
      allow(RedisUtilities::Helpers).to receive(:hash_get_all)
        .with(RedisUtilities::Keys::UNREAD_INBOX_COUNT % { account_id: account.id, member_id: user.id })
        .and_return({ "5" => "3" })

      allow(RedisUtilities::Helpers).to receive(:get)
        .with(RedisUtilities::Keys::UNREAD_MENTION_COUNT % { account_id: account.id, member_id: user.id })
        .and_return("7")
        
      allow(RedisUtilities::Helpers).to receive(:set_members)
        .with(RedisUtilities::Keys::UNREAD_CONVERSATION_SET % { account_id: account.id, member_id: user.id })
        .and_return(["1", "2"])
    end

    it 'returns the current unread counts from Redis' do
      result = service.call

      expect(result).to eq({
        conversations: { "1" => "2" },
        mentions: 7,
        inboxes: { "5" => "3" },
        unread_conversation_ids: ["1", "2"]
      })
    end
  end
end
