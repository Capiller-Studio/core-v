# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::Wise::TransferWorker, type: :worker do
  let(:profile) { create(:affiliate_profile) }
  let(:payout) { create(:affiliate_payout, profile: profile, status: :processing) }

  before do
    allow(RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe '#perform' do
    it 'creates a Wise transfer for the payout under mutex lock' do
      expected_lock = format(::RedisUtilities::Keys::PAYOUT_LOCK, profile_id: profile.id)
      expect(RedisUtilities::MutexHelpers).to receive(:with_lock).with(expected_lock).and_yield
      expect(Affiliates::Payouts::Wise::TransferCreator).to receive(:call).with(payout: payout)

      described_class.new.perform(payout.id)
    end

    it 'returns early if payout is not found' do
      expect(Affiliates::Payouts::Wise::TransferCreator).not_to receive(:call)
      described_class.new.perform(SecureRandom.uuid)
    end

    it 'returns early if payout is already paid' do
      payout.update!(status: :paid)
      expect(Affiliates::Payouts::Wise::TransferCreator).not_to receive(:call)

      described_class.new.perform(payout.id)
    end

    it 'returns early if payout already has an external_id' do
      payout.update!(external_id: 'tr-12345')
      expect(Affiliates::Payouts::Wise::TransferCreator).not_to receive(:call)

      described_class.new.perform(payout.id)
    end
  end
end
