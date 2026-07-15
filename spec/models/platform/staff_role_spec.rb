require 'rails_helper'

RSpec.describe Platform::StaffRole, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:role) }
    it { is_expected.to belong_to(:staff) }
  end

end
