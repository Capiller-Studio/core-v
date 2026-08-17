# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliate::PayoutBatch, type: :model do
  describe 'associations and enums' do
    it { is_expected.to have_many(:payouts).class_name('Affiliate::Payout').with_foreign_key('payout_batch_id').dependent(:nullify).inverse_of(:payout_batch) }
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, processing: 1, funded: 2, failed: 3) }
  end

  describe 'code generation' do
    let(:batch) { create(:affiliate_payout_batch) }

    it 'automatically generates a unique code with BAT prefix' do
      expect(batch.code).to be_present
      expect(batch.code).to start_with('BAT')
    end
  end

  describe '#completed?' do
    let(:batch) { create(:affiliate_payout_batch) }

    it 'returns true when funded or failed' do
      batch.funded!
      expect(batch.completed?).to be(true)

      batch.failed!
      expect(batch.completed?).to be(true)

      batch.processing!
      expect(batch.completed?).to be(false)
    end
  end
end
