# frozen_string_literal: true

module Affiliate
  class Payout < ApplicationRecord
    include CodeGenerator.new(prefix: "AFF", column: :code)

    belongs_to :profile, class_name: "Affiliate::Profile", foreign_key: "affiliate_profile_id", inverse_of: :payouts
    belongs_to :payout_batch, class_name: "Affiliate::PayoutBatch", optional: true, inverse_of: :payouts
    has_one_attached :invoice_pdf

    enum :status, { processing: 0, paid: 1, failed: 2 }
    enum :provider, { manual: 0, wise: 2 }

    def commission_ids
      data["commission_ids"] || []
    end

    def commission_ids=(ids)
      self.data = data.merge("commission_ids" => ids)
    end
  end
end
