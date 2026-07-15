require 'rails_helper'

RSpec.describe CustomerInbox, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:inbox) }
  end

  describe 'Validations' do
    it { is_expected.to have_secure_token(:connection_token) }
  end
end
