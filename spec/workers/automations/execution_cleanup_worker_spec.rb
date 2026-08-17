# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Automations::ExecutionCleanupWorker, type: :worker do
  let(:account) { create(:account) }
  let(:automation) { create(:automation, account: account) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#perform' do
    it 'deletes automation executions older than retention days' do
      old_execution = create(:automation_execution,
        account: account,
        executable: automation,
        resource: conversation,
        executed_at: 95.days.ago
      )
      recent_execution = create(:automation_execution,
        account: account,
        executable: automation,
        resource: conversation,
        executed_at: 10.days.ago
      )

      described_class.new.perform

      expect(AutomationExecution.exists?(old_execution.id)).to be(false)
      expect(AutomationExecution.exists?(recent_execution.id)).to be(true)
    end
  end
end
