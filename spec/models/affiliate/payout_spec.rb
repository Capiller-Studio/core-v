# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliate::Payout, type: :model do
  describe 'associations and enums' do
    it { is_expected.to belong_to(:profile).class_name('Affiliate::Profile').with_foreign_key('affiliate_profile_id').inverse_of(:payouts) }
    it { is_expected.to belong_to(:payout_batch).class_name('Affiliate::PayoutBatch').optional.inverse_of(:payouts) }

    it { is_expected.to define_enum_for(:status).with_values(processing: 0, paid: 1, failed: 2) }
    it { is_expected.to define_enum_for(:provider).with_values(manual: 0, wise: 2) }
  end

  describe 'code generation' do
    let(:payout) { create(:affiliate_payout) }

    it 'automatically generates a unique code with AFF prefix' do
      expect(payout.code).to be_present
      expect(payout.code).to start_with('AFF')
    end
  end

  describe '#commission_ids getter and setter' do
    let(:payout) { create(:affiliate_payout) }

    it 'stores and retrieves commission ids in jsonb data' do
      ids = [SecureRandom.uuid, SecureRandom.uuid]
      payout.commission_ids = ids
      payout.save!

      expect(payout.reload.commission_ids).to eq(ids)
    end
  end
end
