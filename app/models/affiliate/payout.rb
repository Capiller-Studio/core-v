# frozen_string_literal: true

module Affiliate
  class Payout < ApplicationRecord
    include CodeGenerator.new(prefix: "AFF")

    belongs_to :profile, class_name: "Affiliate::Profile", foreign_key: "affiliate_profile_id"
    has_one_attached :invoice_pdf

    enum :status, { processing: 0, paid: 1 }

    def commission_ids
      data["commission_ids"] || []
    end

    def commission_ids=(ids)
      self.data = data.merge("commission_ids" => ids)
    end
  end
end
