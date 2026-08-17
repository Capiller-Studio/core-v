# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliate::Commission, type: :model do
  describe 'associations and enums' do
    it { is_expected.to belong_to(:profile).class_name('Affiliate::Profile').with_foreign_key('affiliate_profile_id').inverse_of(:commissions) }
    it { is_expected.to belong_to(:referral).class_name('Affiliate::Referral').with_foreign_key('affiliate_referral_id').inverse_of(:commissions) }
    it { is_expected.to belong_to(:transaction_record).class_name('Transaction').optional }
    it { is_expected.to belong_to(:original_commission).class_name('Affiliate::Commission').optional.inverse_of(:adjustments) }
    it { is_expected.to have_many(:adjustments).class_name('Affiliate::Commission').with_foreign_key('original_commission_id').dependent(:nullify).inverse_of(:original_commission) }

    it { is_expected.to define_enum_for(:status).with_values(pending: 0, available: 1, paid: 2, voided: 3) }
    it { is_expected.to define_enum_for(:commission_type).with_values(normal: 0, refund: 1, manual_adjustment: 2) }
  end

  describe 'creation' do
    let(:commission) { create(:affiliate_commission, amount: 50.0, status: :pending) }

    it 'creates a valid commission' do
      expect(commission).to be_persisted
      expect(commission.amount).to eq(50.0)
      expect(commission.pending?).to be(true)
    end
  end
end
