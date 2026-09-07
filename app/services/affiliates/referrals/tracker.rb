# frozen_string_literal: true

module Affiliates
  module Referrals
    class Tracker < ApplicationService
      attr_reader :account, :referral_code

      def initialize(account:, referral_code:)
        @account = account
        @referral_code = referral_code
      end

      def call
        return if referral_code.blank?

        profile = ::Affiliate::Profile.find_by(referral_code: referral_code)
        return unless profile

        # Protect against self-referrals or duplicate referral mappings
        return if account.users.exists?(id: profile.user_id)
        return if profile.user&.email.present? && account.users.where("LOWER(email) = ?", profile.user.email.downcase).exists?
        return if profile.user&.email.present? && account.email.present? && account.email.downcase == profile.user.email.downcase
        return if ::Affiliate::Referral.exists?(account: account)

        ::Affiliate::Referral.create!(
          profile: profile,
          account: account,
          status: :active
        )
      rescue StandardError => e
        Rails.logger.error("Failed to map Affiliate Referral: #{e.message}")
      end
    end
  end
end
