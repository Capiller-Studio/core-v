require 'rails_helper'

RSpec.describe PaymentMethod, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:external_id) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:provider).with_values(stripe: 0, paddle: 1) }
    it { is_expected.to define_enum_for(:payment_type).with_values(card: 0, bank_account: 1, paypal: 2) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, expired: 1, removed: 2) }
  end

end
