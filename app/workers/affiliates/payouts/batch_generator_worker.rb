# frozen_string_literal: true

module Affiliates
  module Payouts
    class BatchGeneratorWorker
      include Sidekiq::Worker

      sidekiq_options queue: :payouts, retry: 3

      MAX_BATCH_SIZE = 1000

      # @param profile_ids [Array<String>, nil] specific profiles to pay (nil = all enabled)
      # @param batch_payout [Boolean] true = grouped batch, false = standalone per affiliate
      # @param provider [String] "wise" or "manual"
      def perform(profile_ids = nil, batch_payout = true, provider = "manual")
        lock_key = ::RedisUtilities::Keys::PAYOUT_GENERATION_LOCK

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          profiles = Affiliate::Profile.where(payouts_enabled: true)
          profiles = profiles.where(id: profile_ids) if profile_ids.present?

          return unless profiles.exists?

          if batch_payout
            profiles.find_in_batches(batch_size: MAX_BATCH_SIZE) do |batch_profiles|
              create_batch_and_payouts(batch_profiles, provider)
            end
          else
            profiles.find_each do |profile|
              create_standalone_payout(profile, provider)
            end
          end
        end
      rescue MutexLockError => e
        Rails.logger.warn("Payout Batch Generation skipped: #{e.message}")
      end

      private

      def create_batch_and_payouts(profiles, provider)
        batch = Affiliate::PayoutBatch.create!(status: :pending, provider: provider)

        profiles.each do |profile|
          payout = generate_payout_for(profile, provider)
          payout&.update!(payout_batch_id: batch.id)
        end

        if batch.payouts.empty?
          batch.destroy!
          return
        end

        batch.refresh_total_amount!

        if provider == "wise"
          batch.update!(status: :processing)
          Affiliates::Wise::BatchGroupCreatorWorker.perform_async(batch.id)
        else
          # Manual: mark all payouts and batch as funded atomically
          ActiveRecord::Base.transaction do
            # rubocop:disable Rails/SkipsModelValidations
            batch.payouts.update_all(status: :paid)
            # rubocop:enable Rails/SkipsModelValidations
            batch.update!(status: :funded, funded_at: Time.current)
          end
          batch.payouts.find_each do |p|
            Affiliates::Payouts::InvoiceWorker.perform_async(p.id)
          end
        end
      end

      def create_standalone_payout(profile, provider)
        payout = generate_payout_for(profile, provider)
        return unless payout

        Affiliates::Payouts::Processor.call(payout: payout)
      end

      def generate_payout_for(profile, provider)
        payout = Affiliates::Payouts::Generator.call(profile: profile)
        payout&.update!(provider: provider) if payout && payout.provider != provider
        payout
      rescue StandardError => e
        Rails.logger.error("Payout generation failed for profile #{profile.id}: #{e.message}")
        nil
      end
    end
  end
end
