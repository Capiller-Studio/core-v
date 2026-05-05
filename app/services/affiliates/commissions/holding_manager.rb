# frozen_string_literal: true

module Affiliates
  module Commissions
    class HoldingManager < ApplicationService
      def call
        # Process all pending commissions where the time since genesis
        # strictly eclipses the affiliate profiles custom holding_days block

        ::Affiliate::Commission.pending.find_each do |commission|
          profile = commission.profile
          days_held = (Time.current.to_date - commission.created_at.to_date).to_i

          if days_held >= profile.holding_days
            commission.available!
          end
        rescue StandardError => e
          Rails.logger.error("Failed evaluating Commission ##{commission.id}: #{e.message}")
        end
      end
    end
  end
end
