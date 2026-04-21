# frozen_string_literal: true

module Affiliate
  class Profile < ApplicationRecord
    belongs_to :user
    has_many :referrals, class_name: "Affiliate::Referral", foreign_key: "affiliate_profile_id", dependent: :destroy
    has_many :commissions, class_name: "Affiliate::Commission", foreign_key: "affiliate_profile_id", dependent: :destroy
    has_many :payouts, class_name: "Affiliate::Payout", foreign_key: "affiliate_profile_id", dependent: :destroy

    validates :referral_code, presence: true, uniqueness: true

    after_initialize :set_defaults, if: :new_record?

    private

    def set_defaults
      self.referral_code ||= generate_referral_code
      self.commission_rate ||= 20.0
      self.tenure_months ||= 6
      self.holding_days ||= 30
      self.currency ||= "USD"
      # max_earnings_per_account defaults to nil inherently 
    end

    def generate_referral_code
      loop do
        code = SecureRandom.alphanumeric(8).downcase
        break code unless Affiliate::Profile.exists?(referral_code: code)
      end
    end
  end
end
