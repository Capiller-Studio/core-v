# frozen_string_literal: true

module Affiliate
  class StatsCalculator
    attr_reader :profile

    def initialize(profile)
      @profile = profile
    end

    def calculate
      {
        total_commission: profile.commissions.where(status: [:available, :paid]).sum(:amount),
        pending_commission: profile.commissions.pending.sum(:amount),
        total_paid: profile.payouts.paid.sum(:amount),
        referral_count: profile.referrals.count
      }
    end
  end
end
