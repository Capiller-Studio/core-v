# frozen_string_literal: true

module Affiliates
  class BankDetailsValidator < ApplicationService
    Result = Struct.new(:success?, :error, keyword_init: true)

    attr_reader :profile

    def initialize(profile)
      @profile = profile
    end

    def call
      payment_details = profile.payment_details || {}
      user = profile.user

      return Result.new(success?: false, error: "Not a bank payment method") if !profile.bank?

      if user.blank? || user.address.blank? || user.address.country.blank?
        return Result.new(success?: false, error: "Missing User Address or Country Code")
      end

      case profile.currency
      when 'EUR'
        if payment_details["iban"].blank? || payment_details["account_holder_name"].blank?
          return Result.new(success?: false, error: "Missing IBAN or Account Holder Name for EUR")
        end
      when 'USD'
        if payment_details["routing_number"].blank? || payment_details["account_number"].blank? || payment_details["account_type"].blank? || payment_details["account_holder_name"].blank?
          return Result.new(success?: false, error: "Missing Routing Number, Account Number, Account Type, or Account Holder Name for USD")
        end
      when 'GBP'
        if payment_details["sort_code"].blank? || payment_details["account_number"].blank? || payment_details["account_holder_name"].blank?
          return Result.new(success?: false, error: "Missing Sort Code, Account Number, or Account Holder Name for GBP")
        end
      when 'KRW'
        if payment_details["bank_code"].blank? || payment_details["account_number"].blank? || payment_details["account_holder_name"].blank?
          return Result.new(success?: false, error: "Missing Bank Code, Account Number, or Account Holder Name for KRW")
        end
      else
        return Result.new(success?: false, error: "Unsupported Currency: #{profile.currency}")
      end

      Result.new(success?: true, error: nil)
    end
  end
end
