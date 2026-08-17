# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliates::Payouts::BatchGeneratorWorker, type: :worker do
  let!(:profile1) { create(:affiliate_profile, payouts_enabled: true) }
  let!(:profile2) { create(:affiliate_profile, payouts_enabled: true) }
  let!(:disabled_profile) { create(:affiliate_profile, payouts_enabled: false) }

  describe '#perform' do
    context 'when batch_payout is true' do
      it 'creates a payout batch, generates payouts for eligible profiles, and enqueues BatchGroupCreatorWorker' do
        payout1 = create(:affiliate_payout, profile: profile1)
        payout2 = create(:affiliate_payout, profile: profile2)

        allow(Affiliates::Payouts::Generator).to receive(:call).with(profile: profile1).and_return(payout1)
        allow(Affiliates::Payouts::Generator).to receive(:call).with(profile: profile2).and_return(payout2)

        expect(Affiliates::Wise::BatchGroupCreatorWorker).to receive(:perform_async).with(kind_of(String))

        described_class.new.perform

        batch = Affiliate::PayoutBatch.last
        expect(payout1.reload.payout_batch_id).to eq(batch.id)
        expect(payout2.reload.payout_batch_id).to eq(batch.id)
      end

      it 'filters by profile_ids when provided' do
        payout1 = create(:affiliate_payout, profile: profile1)
        expect(Affiliates::Payouts::Generator).to receive(:call).with(profile: profile1).and_return(payout1)
        expect(Affiliates::Payouts::Generator).not_to receive(:call).with(profile: profile2)

        allow(Affiliates::Wise::BatchGroupCreatorWorker).to receive(:perform_async)

        described_class.new.perform([profile1.id], true)
      end

      it 'does not enqueue worker if no payouts were generated' do
        allow(Affiliates::Payouts::Generator).to receive(:call).and_return(nil)
        expect(Affiliates::Wise::BatchGroupCreatorWorker).not_to receive(:perform_async)

        described_class.new.perform
      end
    end

    context 'when batch_payout is false' do
      it 'generates standalone payouts and processes each immediately' do
        payout1 = create(:affiliate_payout, profile: profile1)
        payout2 = create(:affiliate_payout, profile: profile2)

        allow(Affiliates::Payouts::Generator).to receive(:call).with(profile: profile1).and_return(payout1)
        allow(Affiliates::Payouts::Generator).to receive(:call).with(profile: profile2).and_return(payout2)

        expect(Affiliates::Payouts::Processor).to receive(:call).with(payout: payout1)
        expect(Affiliates::Payouts::Processor).to receive(:call).with(payout: payout2)

        described_class.new.perform(nil, false)
      end
    end

    it 'returns early if no eligible profiles exist' do
      Affiliate::Profile.update_all(payouts_enabled: false)
      expect(Affiliates::Payouts::Generator).not_to receive(:call)

      described_class.new.perform
    end

    it 'rescues and logs errors when generating payout for a profile' do
      allow(Affiliates::Payouts::Generator).to receive(:call).and_raise(StandardError.new('Generation error'))
      expect(Rails.logger).to receive(:error).with(/Payout generation failed for profile/).at_least(:once)

      expect { described_class.new.perform }.not_to raise_error
    end
  end
end
