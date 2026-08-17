# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::Wise::BatchFunderWorker, type: :worker do
  let(:batch) { create(:affiliate_payout_batch, status: :pending) }

  before do
    allow(RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe '#perform' do
    it 'funds the payout batch under mutex lock' do
      expect(RedisUtilities::MutexHelpers).to receive(:with_lock).with("wise:batch_funder:#{batch.id}").and_yield
      expect(Affiliates::Payouts::Wise::BatchFunder).to receive(:call).with(payout_batch: batch)

      described_class.new.perform(batch.id)
    end

    it 'returns early if batch is not found' do
      expect(Affiliates::Payouts::Wise::BatchFunder).not_to receive(:call)
      described_class.new.perform(SecureRandom.uuid)
    end

    it 'returns early if batch is already completed' do
      batch.update!(status: :funded)
      expect(Affiliates::Payouts::Wise::BatchFunder).not_to receive(:call)

      described_class.new.perform(batch.id)
    end
  end
end
