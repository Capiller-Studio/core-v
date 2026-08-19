# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataRetentionWorker, type: :worker do
  let(:plan) { create(:plan, name: Plan::ANABOLIC, limits: { 'data_retention_months' => 3 }) }
  let(:unlimited_plan) { create(:plan, name: Plan::HYPERBOLIC, limits: { 'data_retention_months' => -1 }) }
  let(:account) { create(:account) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  describe '#process_account_retention' do
    it 'prunes messages older than the retention period + 6-month buffer, and deletes conversations only if empty' do
      account.with_shard do
        inbox = create(:inbox, account: account)
        sender = create(:user)

        # Conversation 1: Only contains messages older than 3 months + 6 months buffer (10 months old) -> pruned
        conv1 = create(:conversation, account: account, inbox: inbox, created_at: 10.months.ago)
        old_msg1 = create(:message, account: account, inbox: inbox, conversation: conv1, sender: sender, created_at: 10.months.ago)

        # Conversation 2: Contains an expired message (10 months) AND a recent message (2 weeks) -> only old msg pruned
        conv2 = create(:conversation, account: account, inbox: inbox, created_at: 10.months.ago)
        old_msg2 = create(:message, account: account, inbox: inbox, conversation: conv2, sender: sender, created_at: 10.months.ago)
        new_msg = create(:message, account: account, inbox: inbox, conversation: conv2, sender: sender, created_at: 2.weeks.ago)

        # Conversation 3: Message is past 3 months but within the 6-month safety buffer (5 months old) -> preserved
        conv3 = create(:conversation, account: account, inbox: inbox, created_at: 5.months.ago)
        buffered_msg = create(:message, account: account, inbox: inbox, conversation: conv3, sender: sender, created_at: 5.months.ago)

        described_class.new.send(:process_account_retention, account)

        # Conv 1 was completely empty after old_msg1 was deleted -> pruned
        expect(Message.find_by(id: old_msg1.id)).to be_nil
        expect(Conversation.find_by(id: conv1.id)).to be_nil

        # Conv 2 lost old_msg2 but retains new_msg -> conversation NOT pruned
        expect(Message.find_by(id: old_msg2.id)).to be_nil
        expect(Message.find_by(id: new_msg.id)).to be_present
        expect(Conversation.find_by(id: conv2.id)).to be_present

        # Conv 3 is within the 6-month safety buffer -> preserved
        expect(Message.find_by(id: buffered_msg.id)).to be_present
        expect(Conversation.find_by(id: conv3.id)).to be_present
      end
    end

    it 'does not prune messages or conversations when data_retention_months is -1 (unlimited)' do
      subscription.update!(plan: unlimited_plan)

      account.with_shard do
        inbox = create(:inbox, account: account)
        sender = create(:user)
        conv = create(:conversation, account: account, inbox: inbox, created_at: 24.months.ago)
        msg = create(:message, account: account, inbox: inbox, conversation: conv, sender: sender, created_at: 24.months.ago)

        described_class.new.send(:process_account_retention, account)

        expect(Message.find_by(id: msg.id)).to be_present
        expect(Conversation.find_by(id: conv.id)).to be_present
      end
    end
  end
end
