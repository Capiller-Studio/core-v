# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Automations::TimeTriggerWorker, type: :worker do
  let(:account) { create(:account) }
  let!(:automation) do
    create(:automation,
      account: account,
      status: :active,
      automation_type: :time_trigger,
      event_name: 'hours_since_created',
      conditions: {
        'operator' => 'AND',
        'groups' => [
          {
            'conditions' => [
              { 'attribute' => 'hours_since_created', 'operator' => 'greater_than', 'value' => '24' }
            ]
          }
        ]
      }
    )
  end

  describe '#perform' do
    it 'finds matching conversations exceeding time threshold and enqueues ExecutionWorker' do
      old_conversation = create(:conversation, account: account, status: :active, created_at: 26.hours.ago)
      recent_conversation = create(:conversation, account: account, status: :active, created_at: 2.hours.ago)

      expect(Automations::ExecutionWorker).to receive(:perform_async).with(
        'Automation',
        automation.id,
        'Conversation',
        old_conversation.id,
        'schedule',
        0
      )

      described_class.new.perform
    end

    it 'rescues errors per rule and continues without raising' do
      allow_any_instance_of(described_class).to receive(:process_rule).and_raise(StandardError.new('Rule error'))
      expect(Rails.logger).to receive(:error).with(/TimeTriggerWorker.*Rule #{automation.id} failed/).at_least(:once)

      expect { described_class.new.perform }.not_to raise_error
    end
  end
end
