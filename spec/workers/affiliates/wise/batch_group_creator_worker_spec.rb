# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::Wise::BatchGroupCreatorWorker, type: :worker do
  let(:batch) { create(:affiliate_payout_batch, status: :pending) }
  let(:profile) { create(:affiliate_profile) }
  let!(:payout1) { create(:affiliate_payout, profile: profile, payout_batch_id: batch.id) }
  let!(:payout2) { create(:affiliate_payout, profile: profile, payout_batch_id: batch.id) }

  before do
    allow(RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe '#perform' do
    it 'creates a Wise batch group and queues processor for each child payout' do
      expect(RedisUtilities::MutexHelpers).to receive(:with_lock).with("wise:batch_creator:#{batch.id}").and_yield
      expect(Affiliates::Payouts::Wise::BatchGroupCreator).to receive(:call).with(payout_batch: batch).and_return('bg-12345')

      expect(Affiliates::Payouts::Processor).to receive(:call).with(payout: payout1)
      expect(Affiliates::Payouts::Processor).to receive(:call).with(payout: payout2)

      described_class.new.perform(batch.id)
    end

    it 'returns early if batch is not found' do
      expect(Affiliates::Payouts::Wise::BatchGroupCreator).not_to receive(:call)
      described_class.new.perform(999_999)
    end

    it 'returns early if batch already has an external_id' do
      batch.update!(external_id: 'bg-existing')
      expect(Affiliates::Payouts::Wise::BatchGroupCreator).not_to receive(:call)

      described_class.new.perform(batch.id)
    end
  end
end
