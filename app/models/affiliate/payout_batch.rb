# frozen_string_literal: true

module Affiliate
  class PayoutBatch < ApplicationRecord
    include CodeGenerator.new(prefix: "BAT", column: :code)

    has_many :payouts, class_name: "Affiliate::Payout", foreign_key: "payout_batch_id", dependent: :nullify, inverse_of: :payout_batch

    enum :status, { pending: 0, processing: 1, funded: 2, failed: 3 }
    enum :provider, { manual: 0, wise: 2 }

    before_create :set_default_name

    def completed?
      funded? || failed?
    end

    # Recalculate total_amount from child payouts and persist it
    def refresh_total_amount!
      update!(total_amount: payouts.sum(:amount))
    end

    private

    def set_default_name
      self.name ||= "Payout Run — #{Time.current.strftime('%b %d, %Y')}"
    end
  end
end
