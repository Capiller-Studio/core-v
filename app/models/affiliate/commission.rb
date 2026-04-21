# frozen_string_literal: true

module Affiliate
  class Commission < ApplicationRecord
    belongs_to :profile, class_name: "Affiliate::Profile", foreign_key: "affiliate_profile_id"
    belongs_to :referral, class_name: "Affiliate::Referral", foreign_key: "affiliate_referral_id"
    belongs_to :transaction_record, class_name: "Transaction", foreign_key: "transaction_record_id"
    belongs_to :original_commission, class_name: "Affiliate::Commission", optional: true
    has_many :adjustments, class_name: "Affiliate::Commission", foreign_key: "original_commission_id", dependent: :nullify

    # Pending: Initial payment hold period (prevents chargebacks)
    # Available: Ready to be swept into a Payout batch manually 
    # Paid: Processed via a payout natively 
    # Voided: Reversed if actual transaction was refunded automatically
    enum :status, { pending: 0, available: 1, paid: 2, voided: 3 }
    enum :commission_type, { normal: 0, refund: 1, manual_adjustment: 2 }
  end
end
