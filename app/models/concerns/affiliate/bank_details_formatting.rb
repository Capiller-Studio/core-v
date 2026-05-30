# frozen_string_literal: true

module Affiliate
  module BankDetailsFormatting
    extend ActiveSupport::Concern

    included do
      validate :bank_details_must_be_complete, if: -> { bank? && payment_details.present? }
    end

    def valid_bank_details?
      Affiliates::BankDetailsValidator.call(self).success?
    end

    def wise_bank_details_payload
      details = {}
      account_type_str = ""

      case currency
      when 'EUR'
        account_type_str = "iban"
        details["iban"] = payment_details["iban"]
      when 'USD'
        account_type_str = "aba"
        details["routingNumber"] = payment_details["routing_number"]
        details["accountNumber"] = payment_details["account_number"]
        details["accountType"] = payment_details["account_type"]
      when 'GBP'
        account_type_str = "sort_code"
        details["sortCode"] = payment_details["sort_code"]
        details["accountNumber"] = payment_details["account_number"]
      when 'KRW'
        account_type_str = "korean"
        details["bankCode"] = payment_details["bank_code"]
        details["accountNumber"] = payment_details["account_number"]
      end

      details["dateOfBirth"] = user.dob.to_s if user&.dob.present?

      if user&.address.present? && user.address.country.present?
        details["address"] = {
          "country" => user.address.country.iso,
          "firstLine" => user.address.address1,
          "city" => user.address.city,
          "postCode" => user.address.zipcode
        }.compact
      end

      {
        type: account_type_str,
        details: details
      }
    end

    private

    def bank_details_must_be_complete
      result = Affiliates::BankDetailsValidator.call(self)
      unless result.success?
        errors.add(:payment_details, result.error)
      end
    end
  end
end
