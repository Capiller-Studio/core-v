require 'rails_helper'

RSpec.describe Automation, type: :model do
  subject { build(:automation) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:executions).class_name('AutomationExecution').dependent(:destroy) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:automation_type).with_values(macro: 0, event_trigger: 1, time_trigger: 2) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }

    context 'when event_trigger' do
      subject { build(:automation, automation_type: :event_trigger) }

      it { is_expected.to validate_presence_of(:event_name) }
    end

    context 'when macro' do
      subject { build(:automation, :macro) }

      it { is_expected.to validate_presence_of(:user_id) }
    end
  end

  describe 'Flags' do
    it 'responds to stop_processing' do
      automation = build(:automation)
      expect(automation).to respond_to(:stop_processing)
      expect(automation).to respond_to(:stop_processing=)
    end
  end
end
