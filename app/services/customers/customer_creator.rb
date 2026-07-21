# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Customers
  class CustomerCreator < ApplicationService
    attr_accessor :params, :customer, :account, :inbox, :customer_inbox,
                  :external_id, :full_phone_number, :email

    def initialize(account:, inbox:, external_id: nil, email: nil,
                   full_phone_number: nil, params: {})
      self.account             = account
      self.inbox               = inbox
      self.external_id         = external_id
      self.email               = email
      self.full_phone_number   = full_phone_number
      self.full_phone_number ||= "#{params[:phone_code]}#{params[:phone_number]}"
      self.params              = params
    end

    def call
      self.customer_inbox = inbox.customer_inboxes.find_by(external_id:) if external_id.present?
      return customer_inbox.customer if customer_inbox

      ActiveRecord::Base.transaction do
        find_or_create_customer
        attach_avatar_if_present
      end

      customer_inbox&.customer
    end

    private

    def find_or_create_customer
      find_customer || create_customer
      create_customer_inbox
    end

    def attach_avatar_if_present
      url = params[:avatar_url].presence || generate_default_avatar_url
      return unless url

      ::Utilities::ActiveStorageDownloader.attach(
        record: customer,
        attachment_name: :avatar,
        url: url
      )
    end

    def generate_default_avatar_url
      gender_path =
        case params[:gender].to_s.downcase
        when "female" then "girl"
        else "boy" # Fallback randomized
        end

      seed = CGI.escape(params[:name] || params[:first_name] || external_id.to_s || customer.identifier.to_s)
      "https://avatar.iran.liara.run/public/#{gender_path}?username=#{seed}"
    end

    def find_customer
      find_customer_by_external_id || find_customer_by_email || find_customer_by_phone_number
    end

    def find_customer_by_external_id
      return if external_id.blank?

      self.customer = account.customers.find_by(external_id:)
    end

    def find_customer_by_email
      return if email.blank?

      self.customer = account.customers.find_by(email: email.downcase)
    end

    def find_customer_by_phone_number
      return if full_phone_number.blank?

      self.customer = account.customers.find_by(full_phone_number:)
    end

    def generate_fallback_name
      if params[:first_name].present? || params[:last_name].present?
        [params[:first_name], params[:last_name]].compact_blank.join(" ")
      elsif email.present?
        email.split("@").first
      elsif full_phone_number.present?
        full_phone_number
      elsif external_id.present?
        "Customer #{external_id}"
      else
        "Unknown Customer"
      end
    end

    def create_customer
      # TODO: Fix address
      self.customer = account.customers.create!(
        name: params[:name].presence || generate_fallback_name,
        full_phone_number:,
        # phone_code: params[:phone_code],
        # phone_number: params[:phone_number],
        first_name: params[:first_name],
        middle_name: params[:middle_name],
        last_name: params[:last_name],
        email:,
        external_id:,
        gender: params[:gender],
        address: Address.create!
      )
    end

    def create_customer_inbox
      self.customer_inbox = CustomerInboxCreator.call(
        customer: @customer,
        inbox:,
        external_id:,
        account:
      )
    end
  end
end
