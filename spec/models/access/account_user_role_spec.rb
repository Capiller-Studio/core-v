require 'rails_helper'

RSpec.describe Access::AccountUserRole, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:account_user) }
    it { is_expected.to belong_to(:role) }
  end

end
