# frozen_string_literal: true

module Affiliates
  module Payouts
    # Read-only preview of what a payout run would produce. No records are created,
    # no commissions are marked as paid, no Wise API calls are made.
    #
    # Returns an array of hashes, one per eligible profile:
    #   [
    #     { profile_id: "...", name: "...", email: "...", referral_code: "...",
    #       currency: "USD", amount: 120.50, commission_count: 3 },
    #     ...
    #   ]
    #
    # Usage:
    #   DryRun.call(profile_ids: [...])
    #   # => Array<Hash>
    class DryRun < ApplicationService
      attr_reader :profile_ids

      def initialize(profile_ids: nil)
        @profile_ids = profile_ids
      end

      def call
        profiles = eligible_profiles
        return [] unless profiles.exists?

        preview = []

        profiles.includes(:user).find_each do |profile|
          result = calculate_payout_for(profile)
          preview << result if result
        end

        preview
      end

      private

      def eligible_profiles
        scope = Affiliate::Profile.where(payouts_enabled: true)
        scope = scope.where(id: profile_ids) if profile_ids.present?
        scope
      end

      def calculate_payout_for(profile)
        available_commissions = profile.commissions.available
        return nil if available_commissions.empty?

        total = available_commissions.sum(:amount)
        return nil if total <= 0

        {
          profile_id: profile.id,
          name: profile.user&.display_name.presence || profile.user&.name.presence || profile.user&.email,
          email: profile.user&.email,
          referral_code: profile.referral_code,
          currency: profile.currency,
          amount: total,
          commission_count: available_commissions.count,
          valid_bank_details: profile.valid_bank_details?
        }
      rescue StandardError => e
        Rails.logger.error("DryRun calculation failed for profile #{profile.id}: #{e.message}")
        nil
      end
    end
  end
end
