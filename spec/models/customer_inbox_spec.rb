require 'rails_helper'

RSpec.describe CustomerInbox, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to have_many(:customer_devices).dependent(:delete_all) }
  end

  describe 'Validations' do
    it { is_expected.to have_secure_token(:connection_token) }
  end
end
