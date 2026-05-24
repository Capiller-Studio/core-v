# frozen_string_literal: true

module Affiliates
  module Payouts
    class BatchGeneratorWorker
      include Sidekiq::Worker

      sidekiq_options queue: :payouts, retry: 3

      MAX_BATCH_SIZE = 1000

      def perform(profile_ids = nil, batch_payout = true)
        profiles = Affiliate::Profile.where(payouts_enabled: true)
        profiles = profiles.where(id: profile_ids) if profile_ids.present?

        return unless profiles.exists?

        if batch_payout
          profiles.in_batches(of: MAX_BATCH_SIZE) do |batch_profiles|
            create_batch_and_payouts(batch_profiles)
          end
        else
          profiles.find_each do |profile|
            create_standalone_payout(profile)
          end
        end
      end

      private

      def create_batch_and_payouts(profiles)
        batch = Affiliate::PayoutBatch.create!(status: :pending)

        profiles.each do |profile|
          payout = generate_payout_for(profile)
          payout.update!(payout_batch_id: batch.id) if payout
        end

        return if batch.payouts.empty?

        Affiliates::Wise::BatchGroupCreatorWorker.perform_async(batch.id)
      end

      def create_standalone_payout(profile)
        payout = generate_payout_for(profile)
        return unless payout

        Affiliates::Payouts::Processor.call(payout: payout)
      end

      def generate_payout_for(profile)
        Affiliates::Payouts::Generator.call(profile: profile)
      rescue StandardError => e
        Rails.logger.error("Payout generation failed for profile #{profile.id}: #{e.message}")
        nil
      end
    end
  end
end
