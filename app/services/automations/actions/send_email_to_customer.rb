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

        # TODO: Use a mailer service that renders the template with conversation/customer context
        # For now, enqueue the email delivery job
        # Automations::EmailDeliveryWorker.perform_async(template.id, customer.id, resource.id)
        Rails.logger.info("[Automations::SendEmailToCustomer] Template #{template.id} → #{customer.email}")
      end
    end
  end
end
