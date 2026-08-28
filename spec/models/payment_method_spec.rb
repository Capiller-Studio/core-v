# frozen_string_literal: true

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

  describe 'Scopes' do
    let(:account) { create(:account) }
    let!(:active_pm) { create(:payment_method, account: account, status: :active, default_method: true) }
    let!(:expired_pm) { create(:payment_method, account: account, status: :expired, default_method: false) }

    describe '.active_methods' do
      it 'returns only active payment methods' do
        expect(described_class.active_methods).to include(active_pm)
        expect(described_class.active_methods).not_to include(expired_pm)
      end
    end

    describe '.default_method' do
      it 'returns only active default payment methods' do
        expect(described_class.default_method).to include(active_pm)
        expect(described_class.default_method).not_to include(expired_pm)
      end
    end
  end

  describe 'Instance Methods' do
    let(:account) { create(:account) }
    let(:pm) { create(:payment_method, account: account, brand: 'Visa', last_four: '4242') }

    describe '#display_name' do
      it 'formats brand and last four digits' do
        expect(pm.display_name).to eq('Visa ****4242')
      end
    end

    describe '#expired?' do
      it 'returns true for past dates' do
        pm.expiry_month = 1
        pm.expiry_year = 2020
        expect(pm.expired?).to be true
      end

      it 'returns false for future dates' do
        pm.expiry_month = 12
        pm.expiry_year = 2035
        expect(pm.expired?).to be false
      end

      it 'returns false if expiry dates are missing' do
        pm.expiry_month = nil
        pm.expiry_year = nil
        expect(pm.expired?).to be false
      end
    end

    describe '#make_default!' do
      let!(:pm1) { create(:payment_method, account: account, default_method: true) }
      let!(:pm2) { create(:payment_method, account: account, default_method: false) }

      it 'promotes self to default and unsets previous default' do
        pm2.make_default!
        expect(pm2.reload.default_method).to be true
        expect(pm1.reload.default_method).to be false
      end
    end
  end
end
