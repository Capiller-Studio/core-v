require 'rails_helper'

RSpec.describe UnreadCounts::Increment do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:customer) { create(:customer, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    allow(UnreadCounts::Broadcast).to receive(:call)
    allow(RedisUtilities::Helpers).to receive(:hash_increment)
    allow(RedisUtilities::Helpers).to receive(:set_add)
    allow(RedisUtilities::Helpers).to receive(:increment)
  end

  describe '#call' do
    context 'when resource is a Message' do
      let(:message) { create(:message, account: account, conversation: conversation, sender: customer) }
      let(:service) { described_class.new(message) }

      it 'increments counts for conversation members and broadcasts' do
        create(:conversation_member, conversation: conversation, member: user1)
        
        service.call

        expect(RedisUtilities::Helpers).to have_received(:hash_increment)
          .with(instance_of(String), conversation.id, 1).at_least(:once)
        expect(RedisUtilities::Helpers).to have_received(:hash_increment)
          .with(instance_of(String), inbox.id, 1).at_least(:once)
        expect(RedisUtilities::Helpers).to have_received(:set_add)
          .with(instance_of(String), conversation.id).at_least(:once)
          
        expect(UnreadCounts::Broadcast).to have_received(:call).with(member: user1, account_id: account.id).at_least(:once)
      end
    end

    context 'when resource is a Mention' do
      let(:message) { create(:message, account: account, conversation: conversation) }
      let(:mention) { create(:mention, account: account, resource: message, mentioned: user1) }
      let(:service) { described_class.new(mention) }

      it 'increments mention count and broadcasts' do
        service.call

        expect(RedisUtilities::Helpers).to have_received(:increment).with(instance_of(String)).at_least(:once)
        expect(UnreadCounts::Broadcast).to have_received(:call).with(member: user1, account_id: account.id).at_least(:once)
      end
    end
  end
end
