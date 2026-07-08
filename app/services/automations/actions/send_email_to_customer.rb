# frozen_string_literal: true

module Automations
  module Actions
    class SendEmailToCustomer < BaseAction
      def call
        require_conversation!

        template_id = params[:email_template_id]
        raise("email_template_id is required") if template_id.blank?

        template = account.email_templates.find(template_id)
        customer = resource.customers.first

        raise("No customer found on conversation") unless customer
        raise("Customer has no email") if customer.email.blank?

        # Hand off the template rendering and message creation to the worker
        # so we can properly evaluate the Liquid context in the background and dispatch via SMTP.
        Automations::EmailDeliveryWorker.perform_async(template.id, customer.id, resource.id, account.id)
        
        Rails.logger.info("[Automations::SendEmailToCustomer] Enqueued template #{template.id} for #{customer.email}")
      end
    end
  end
end
