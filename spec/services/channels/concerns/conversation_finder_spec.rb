require 'rails_helper'

RSpec.describe Channels::Concerns::ConversationFinder do
  let(:dummy_class) do
    Class.new do
      include Channels::Concerns::ConversationFinder
    end
  end

  let(:finder) { dummy_class.new }
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }
  let(:inbox) { create(:inbox, account: account, reopen_window_seconds: reopen_window_seconds) }
  let(:reopen_window_seconds) { 86400 } # 1 day

  describe '#find_or_reopen_conversation' do
    context 'when no recent conversation exists' do
      it 'returns nil' do
        expect(finder.find_or_reopen_conversation(customer, inbox, account)).to be_nil
      end
    end

    context 'when an active conversation exists' do
      let!(:conversation) { create(:conversation, account: account, inbox: inbox, status: :active) }
      let!(:member) { create(:conversation_member, account: account, conversation: conversation, member: customer) }

      it 'returns the active conversation' do
        expect(finder.find_or_reopen_conversation(customer, inbox, account)).to eq(conversation)
      end
    end

    context 'when a resolved conversation exists' do
      let!(:conversation) do
        create(:conversation, account: account, inbox: inbox, status: :resolved, status_changed_at: status_changed_at)
      end
      let!(:member) { create(:conversation_member, account: account, conversation: conversation, member: customer) }

      context 'and it is within the reopen window' do
        let(:status_changed_at) { 1.hour.ago }

        it 'reopens and returns the conversation' do
          result = finder.find_or_reopen_conversation(customer, inbox, account)
          expect(result).to eq(conversation)
          expect(result.reload.status).to eq('active')
        end
      end

      context 'and it is outside the reopen window' do
        let(:status_changed_at) { 2.days.ago }

        it 'returns nil to force creating a new conversation' do
          result = finder.find_or_reopen_conversation(customer, inbox, account)
          expect(result).to be_nil
          expect(conversation.reload.status).to eq('resolved')
        end
      end

      context 'and reopen window is disabled (0)' do
        let(:reopen_window_seconds) { 0 }
        let(:status_changed_at) { 1.minute.ago }

        it 'returns nil' do
          result = finder.find_or_reopen_conversation(customer, inbox, account)
          expect(result).to be_nil
        end
      end
    end
  end
end
