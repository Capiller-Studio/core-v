# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SlaCheckWorker, type: :worker do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:inbox_user) { create(:inbox_user, inbox: inbox, user: user) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let(:sla_policy) { create(:sla_policy, account: account) }
  let!(:conversation_sla) do
    create(:conversation_sla,
      account: account,
      conversation: conversation,
      sla_policy: sla_policy,
      target_first_response_at: 10.minutes.ago,
      status: :pending
    )
  end

  describe '#perform' do
    it 'finds breached active SLAs, marks them breached, and creates notifications' do
      expect {
        described_class.new.perform
      }.to change(Notification, :count).by_at_least(1)

      conversation_sla.reload
      expect(conversation_sla.status).to eq('failed')
    end

    it 'does not mark SLA as breached if agent responded before target' do
      conversation.update_column(:first_respond_at, 15.minutes.ago)

      described_class.new.perform

      conversation_sla.reload
      expect(conversation_sla.status).to eq('pending')
    end

    it 'rescues errors and logs SYSTEM_WORKER_FAILED to SystemLogs::Logger' do
      allow(ShardRecord).to receive(:connected_to).and_raise(StandardError.new('DB connection lost'))
      expect(SystemLogs::Logger).to receive(:call).with(
        hash_including(
          event_key: SystemLogs::EventKeys::SYSTEM_WORKER_FAILED,
          level: :error
        )
      )

      described_class.new.perform
    end
  end
end
