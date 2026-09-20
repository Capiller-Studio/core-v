# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Customers
  class CustomerInboxCreator < ApplicationService
    attr_accessor :customer, :account, :customer_inbox, :inbox,
                  :external_id

    def initialize(account:, customer:, inbox:, external_id: nil)
      self.account           = account
      self.inbox             = inbox
      self.external_id       = external_id
      self.customer          = customer
    end

    def call
      self.external_id ||= find_external_id

      if external_id.present?
        self.customer_inbox = create_customer_inbox
        ::Identities::AutomationManager.call(customer: customer, inbox: inbox, external_id: external_id)
      end

      self.customer_inbox
    end

    private

    def find_external_id
      method_name = "#{inbox.channel_type.underscore.parameterize(separator: "_")}_external_id"
      if respond_to?(method_name, true)
        send(method_name)
      else
        channel_api_external_id
      end
    end

    def channel_email_external_id
      customer.email
    end

    def channel_short_message_external_id
      customer.full_phone_number
    end

    def channel_whatsapp_external_id
      customer.full_phone_number.to_s.delete("+")
    end

    def channel_api_external_id
      customer.external_id.presence ||
        customer.email.presence ||
        customer.full_phone_number.presence ||
        customer.username.presence ||
        fallback_unique_external_id
    end

    def channel_web_widget_external_id
      channel_api_external_id
    end

    def channel_contact_form_external_id
      channel_api_external_id
    end

    def channel_facebook_page_external_id
      customer.external_id
    end

    def channel_instagram_external_id
      customer.external_id
    end

    def fallback_unique_external_id
      if customer&.id.present? && !inbox.customer_inboxes.exists?(external_id: customer.id.to_s)
        return customer.id.to_s
      end

      loop do
        candidate = SecureRandom.uuid
        break candidate unless inbox.customer_inboxes.exists?(external_id: candidate)
      end
    end

    def create_customer_inbox
      customer.customer_inboxes.find_or_create_by!(
        inbox:,
        external_id:
      )
    end
  end
end
