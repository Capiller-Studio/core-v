# frozen_string_literal: true

module Affiliates
  class AnalyticsEngine < ApplicationService
    attr_reader :profile

    def initialize(profile:)
      @profile = profile
    end

    def call
      # Returns dynamic frontend transparency blocks naturally calculating physical ledgers!
      {
        total_clicks: total_clicks,
        total_referrals: total_referrals,
        conversion_rate: conversion_rate,
        total_earnings: total_earnings,
        pending_balance: pending_balance,
        available_balance: available_balance,
        paid_balance: paid_balance
      }
    end

    private

    def total_clicks
      @total_clicks ||= ::Affiliate::Click.where(profile: profile).count
    end

    def total_referrals
      @total_referrals ||= profile.referrals.count
    end

    def conversion_rate
      return 0.0 if total_clicks.zero?
      
      ((total_referrals.to_f / total_clicks) * 100.0).round(2)
    end

    def total_earnings
      @total_earnings ||= profile.commissions.where.not(status: :voided).sum(:amount).to_f
    end

    def pending_balance
      profile.commissions.pending.sum(:amount).to_f
    end
    
    def available_balance
      profile.commissions.available.sum(:amount).to_f
    end

    def paid_balance
      profile.commissions.paid.sum(:amount).to_f
    end
  end
end
