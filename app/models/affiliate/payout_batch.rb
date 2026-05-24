# frozen_string_literal: true

module Affiliate
  class PayoutBatch < ApplicationRecord
    include CodeGenerator.new(prefix: "BAT")

    has_many :payouts, class_name: "Affiliate::Payout", foreign_key: "payout_batch_id", dependent: :nullify, inverse_of: :payout_batch

    enum :status, { pending: 0, processing: 1, funded: 2, failed: 3 }

    def completed?
      funded? || failed?
    end
  end
end
