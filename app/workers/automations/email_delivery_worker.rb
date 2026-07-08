# frozen_string_literal: true

module Automations
  class EmailDeliveryWorker
    include Sidekiq::Worker
    sidekiq_options queue: :mailers, retry: 3

    def perform(template_id, customer_id, conversation_id, account_id)
      account = Account.find_by(id: account_id)
      return unless account

      account.with_shard do
        template = account.email_templates.find_by(id: template_id)
        customer = Customer.find_by(id: customer_id)
        conversation = account.conversations.find_by(id: conversation_id)

        return unless template && customer && conversation

        inbox = conversation.inbox
        
        # Prepare Liquid context
        liquid_vars = {
          "customer" => { "name" => customer.name, "email" => customer.email },
          "agent"    => { "name" => conversation.assignee&.name, "email" => conversation.assignee&.email },
          "account"  => { "name" => account.name },
          "inbox"    => { "name" => inbox.name }
        }

        # Render content
        rendered_html = render_template(template.html_content, liquid_vars)
        rendered_text = render_template(template.text_content, liquid_vars)

        # Create the message
        message = conversation.messages.create!(
          account: account,
          inbox: inbox,
          content: rendered_html.presence || rendered_text.presence,
          visibility: "public",
          content_type: :email,
          sender: account,
          source: conversation.source,
          data: { email_template_id: template.id, target_email: customer.email }
        )

        # Dispatch the message using the core delivery worker
        Messages::DeliveryWorker.perform_async(message.account_id, message.id)
      end
    end

    private

    def render_template(content, vars)
      return "" if content.blank?
      
      # Assuming we are using Liquid template rendering as seen in CsatDispatcherWorker
      Liquid::Template.parse(content).render(vars)
    rescue StandardError => e
      Rails.logger.error("[Automations::EmailDeliveryWorker] Error rendering template: #{e.message}")
      content
    end
  end
end
