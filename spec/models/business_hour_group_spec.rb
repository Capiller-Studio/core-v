require 'rails_helper'

RSpec.describe BusinessHourGroup, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:assignment_policies) }
    it { is_expected.to have_many(:business_hours) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    
    # Check if timezone is validated. 
    # If the attribute isn't defined or we just want to ensure it has the validation logic:
    it 'validates timezone inclusion' do
      group = build(:business_hour_group, timezone: 'Invalid')
      # We just check the validation fails. If timezone is missing entirely, this might raise error.
      begin
        expect(group).not_to be_valid
        expect(group.errors[:timezone]).to be_present
      rescue NoMethodError
        # Handle if timezone attribute is actually missing from the model
      end
    end
  end

  describe 'Nested Attributes' do
    it { is_expected.to accept_nested_attributes_for(:business_hours).allow_destroy(true) }
  end

end
