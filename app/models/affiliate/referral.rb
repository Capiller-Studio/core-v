# frozen_string_literal: true

module Affiliate
  class Referral < ApplicationRecord
    belongs_to :profile, class_name: "Affiliate::Profile", foreign_key: "affiliate_profile_id"
    belongs_to :account

    has_many :commissions, class_name: "Affiliate::Commission", foreign_key: "affiliate_referral_id", dependent: :destroy

    enum :status, { active: 0, expired: 1 }

    def remaining_tenure_months
      # Calculates how many months left based on Affiliates limits organically 
      months_elapsed = ((Time.current.year * 12 + Time.current.month) - (created_at.year * 12 + created_at.month))
      [profile.tenure_months - months_elapsed, 0].max
    end

    def total_revenue
      commissions.joins(:transaction_record).sum("transactions.amount")
    end

    def total_commission
      commissions.sum(:amount)
    end
  end
end
