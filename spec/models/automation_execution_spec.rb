require 'rails_helper'

RSpec.describe AutomationExecution, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:executable) }
    it { is_expected.to belong_to(:resource) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:executed_at) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(success: 0, failed: 1, skipped: 2) }
    it { is_expected.to define_enum_for(:triggered_by).with_values(event: 0, schedule: 1, manual: 2) }
  end

  describe 'Scopes' do
    let(:account) { create(:account) }

    it '.recent orders by executed_at descending' do
      a1 = create(:automation_execution, account: account, executed_at: 1.day.ago)
      a2 = create(:automation_execution, account: account, executed_at: Time.current)
      
      expect(AutomationExecution.where(id: [a1.id, a2.id]).recent).to eq([a2, a1])
    end

    it '.failures returns only failed executions' do
      a1 = create(:automation_execution, account: account, status: :failed)
      a2 = create(:automation_execution, account: account, status: :success)

      expect(AutomationExecution.where(id: [a1.id, a2.id]).failures).to include(a1)
      expect(AutomationExecution.where(id: [a1.id, a2.id]).failures).not_to include(a2)
    end
  end
end
