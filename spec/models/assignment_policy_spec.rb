require 'rails_helper'

RSpec.describe AssignmentPolicy, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:assignment_policy_inboxes) }
    it { is_expected.to belong_to(:business_hour_group).optional }
    it { is_expected.to have_many(:inboxes) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:max_conversations_per_agent).only_integer.is_greater_than(0).allow_nil }
    it { is_expected.to validate_numericality_of(:idle_timeout_minutes).only_integer.is_greater_than(0).allow_nil }

    it 'validates business_hour_group_id presence if respect_business_hours is true' do
      policy = build(:assignment_policy, respect_business_hours: true, business_hour_group_id: nil)
      expect(policy).not_to be_valid
      expect(policy.errors[:business_hour_group]).to include(I18n.t("activerecord.errors.models.assignment_policy.attributes.business_hour_group.required_with_business_hours", default: "must be provided when respect business hours is enabled"))
    end

    it 'validates conditions via AutomationValidator' do
      # Just verify that invalid conditions trigger errors
      policy = build(:assignment_policy, conditions: { "operator" => "INVALID" })
      allow(Automations::AutomationValidator).to receive(:new).and_return(double(call: ['invalid operator']))
      expect(policy).not_to be_valid
      expect(policy.errors[:base]).to include('invalid operator')
    end
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:strategy).with_values(round_robin: 0, load_balanced: 1, skills_based: 2, manual: 3) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1) }
  end

  describe 'Callbacks' do
    it 'assigns next position before create' do
      account = create(:account)
      create(:assignment_policy, account: account, position: 2)
      new_policy = create(:assignment_policy, account: account)
      expect(new_policy.position).to eq(3)
    end
  end

  describe 'Scopes' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }

    it '.ordered returns policies by position' do
      p1 = create(:assignment_policy, account: account, position: 2)
      p2 = create(:assignment_policy, account: account, position: 1)
      expect(AssignmentPolicy.where(id: [p1.id, p2.id]).ordered).to eq([p2, p1])
    end

    it '.for_inbox returns active policies linked to the inbox' do
      active_policy = create(:assignment_policy, account: account, status: :active)
      inactive_policy = create(:assignment_policy, account: account, status: :inactive)
      create(:assignment_policy_inbox, assignment_policy: active_policy, inbox: inbox)
      create(:assignment_policy_inbox, assignment_policy: inactive_policy, inbox: inbox)

      expect(AssignmentPolicy.for_inbox(inbox)).to include(active_policy)
      expect(AssignmentPolicy.for_inbox(inbox)).not_to include(inactive_policy)
    end
  end

  describe 'Instance Methods' do
    let(:policy) { create(:assignment_policy, status: :active) }

    describe '#toggle!' do
      it 'toggles status from active to inactive' do
        policy.toggle!
        expect(policy.status).to eq('inactive')
      end

      it 'toggles status from inactive to active' do
        policy.update!(status: :inactive)
        policy.toggle!
        expect(policy.status).to eq('active')
      end
    end

    describe '#within_business_hours?' do
      it 'returns true if respect_business_hours is false' do
        policy.respect_business_hours = false
        expect(policy.within_business_hours?).to be true
      end

      it 'calls BusinessHoursChecker if respect_business_hours is true' do
        bhg = create(:business_hour_group, account: policy.account)
        policy.update!(respect_business_hours: true, business_hour_group: bhg)
        
        allow(AssignmentPolicies::BusinessHoursChecker).to receive(:call).and_return(false)
        expect(policy.within_business_hours?).to be false
        expect(AssignmentPolicies::BusinessHoursChecker).to have_received(:call)
      end
    end
  end
end
