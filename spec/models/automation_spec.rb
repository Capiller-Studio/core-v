require 'rails_helper'

RSpec.describe Automation, type: :model do
  subject { build(:automation) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:executions).dependent(:destroy) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:automation_type).with_values(event_trigger: 1, time_trigger: 2) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }

    context 'when event_trigger' do
      subject { build(:automation, automation_type: :event_trigger) }

      it { is_expected.to validate_presence_of(:event_name) }
    end

    context 'validates conditions via AutomationValidator' do
      it 'triggers errors on invalid conditions' do
        auto = build(:automation, conditions: { "operator" => "INVALID" })
        allow(Automations::AutomationValidator).to receive(:new).and_return(double(call: ['invalid operator']))
        expect(auto).not_to be_valid
        expect(auto.errors[:base]).to include('invalid operator')
      end
    end
  end

  describe 'Flags' do
    it 'responds to stop_processing' do
      automation = build(:automation)
      expect(automation).to respond_to(:stop_processing)
      expect(automation).to respond_to(:stop_processing=)
    end
  end

  describe 'Callbacks' do
    it 'assigns next position before create' do
      account = create(:account)
      create(:automation, account: account, position: 2)
      new_auto = create(:automation, account: account)
      expect(new_auto.position).to eq(3)
    end
  end

  describe 'Scopes' do
    let(:account) { create(:account) }

    it '.event_triggers_for returns active event triggers ordered by position' do
      a1 = create(:automation, account: account, event_name: 'test', position: 2, status: :active)
      a2 = create(:automation, account: account, event_name: 'test', position: 1, status: :active)
      a3 = create(:automation, account: account, event_name: 'test', status: :inactive)
      a4 = create(:automation, account: account, event_name: 'other', status: :active)

      results = Automation.where(id: [a1.id, a2.id, a3.id, a4.id]).event_triggers_for('test')
      expect(results).to eq([a2, a1])
    end

    it '.time_triggers returns active time triggers ordered by position' do
      a1 = create(:automation, account: account, automation_type: :time_trigger, position: 2, status: :active)
      a2 = create(:automation, account: account, automation_type: :time_trigger, position: 1, status: :active)
      a3 = create(:automation, account: account, automation_type: :time_trigger, status: :inactive)

      results = Automation.where(id: [a1.id, a2.id, a3.id]).time_triggers
      expect(results).to eq([a2, a1])
    end
  end

  describe 'Instance Methods' do
    describe '#duplicate' do
      let(:auto) { create(:automation) }

      it 'duplicates the automation with new name and inactive status' do
        copy = auto.duplicate
        expect(copy.name).to eq("#{auto.name} (copy)")
        expect(copy.status).to eq('inactive')
        expect(copy.is_system).to be false
        expect(copy.position).to be_nil
      end

      it 'uses provided name if passed' do
        copy = auto.duplicate(new_name: 'Custom Name')
        expect(copy.name).to eq('Custom Name')
      end
    end
  end

  describe 'Class Methods' do
    describe '.reorder!' do
      let(:account) { create(:account) }
      let!(:a1) { create(:automation, account: account, position: 1) }
      let!(:a2) { create(:automation, account: account, position: 2) }
      let!(:a3) { create(:automation, account: account, position: 3) }

      it 'reorders automations based on ID array' do
        Automation.reorder!([a3.id, a1.id, a2.id])
        expect(a3.reload.position).to eq(1)
        expect(a1.reload.position).to eq(2)
        expect(a2.reload.position).to eq(3)
      end
    end
  end
end
