# frozen_string_literal: true

module Affiliate
  class Profile < ApplicationRecord
    include Affiliate::BankDetailsFormatting

    belongs_to :user, inverse_of: :affiliate_profile
    has_many :referrals, class_name: "Affiliate::Referral", foreign_key: "affiliate_profile_id", dependent: :destroy, inverse_of: :profile
    has_many :commissions, class_name: "Affiliate::Commission", foreign_key: "affiliate_profile_id", dependent: :destroy, inverse_of: :profile
    has_many :payouts, class_name: "Affiliate::Payout", foreign_key: "affiliate_profile_id", dependent: :destroy, inverse_of: :profile

    validates :referral_code, presence: true, uniqueness: true
    
    enum :payment_method_type, { bank: 0 }

    after_initialize :set_defaults, if: :new_record?

    private

    def set_defaults
      self.referral_code ||= generate_referral_code
      self.commission_rate ||= 20.0
      self.tenure_months ||= 6
      self.holding_days ||= 30
      self.currency ||= "USD" if has_attribute?(:currency)
      self.payouts_enabled = false if has_attribute?(:payouts_enabled) && self.payouts_enabled.nil?
      self.payment_method_type = "bank" if has_attribute?(:payment_method_type) && self.payment_method_type.nil?
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
