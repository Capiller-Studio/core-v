require 'rails_helper'

RSpec.describe AssignmentPolicyInbox, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:assignment_policy) }
    it { is_expected.to belong_to(:inbox) }
  end

  describe 'Validations' do
    subject { create(:assignment_policy_inbox) }
    
    it { is_expected.to validate_uniqueness_of(:inbox_id).scoped_to(:assignment_policy_id).case_insensitive }
  end
end
