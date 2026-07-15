require 'rails_helper'

RSpec.describe ConversationMember, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:member) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:role).with_values(participant: 0, watcher: 1) }
  end

  describe 'Scopes' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:user) { create(:user) }
    let(:watcher_user) { create(:user) }
    let(:customer) { create(:customer, account: account) }

    before do
      create(:account_user, account: account, user: user)
      create(:account_user, account: account, user: watcher_user)
    end

    let!(:participant) { create(:conversation_member, account: account, conversation: conversation, member: user, role: :participant) }
    let!(:watcher) { create(:conversation_member, account: account, conversation: conversation, member: watcher_user, role: :watcher) }
    let!(:customer_member) { create(:conversation_member, account: account, conversation: conversation, member: customer, role: :participant) }

    it 'filters participants' do
      expect(ConversationMember.participants).to include(participant, customer_member)
      expect(ConversationMember.participants).not_to include(watcher)
    end

    it 'filters watchers' do
      expect(ConversationMember.watchers).to include(watcher)
      expect(ConversationMember.watchers).not_to include(participant)
    end

    it 'filters agents' do
      expect(ConversationMember.agents).to include(participant, watcher)
      expect(ConversationMember.agents).not_to include(customer_member)
    end
  end

  describe '#mark_as_read!' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:user) { create(:user) }
    let(:member) { create(:conversation_member, account: account, conversation: conversation, member: user) }

    it 'updates last_seen_at and calls UnreadCounts::Reset' do
      allow(UnreadCounts::Reset).to receive(:call)
      
      Timecop.freeze do
        member.mark_as_read!
        expect(member.reload.last_seen_at.to_i).to eq(Time.current.to_i)
        expect(UnreadCounts::Reset).to have_received(:call).with(conversation, user)
      end
    end
  end
end
