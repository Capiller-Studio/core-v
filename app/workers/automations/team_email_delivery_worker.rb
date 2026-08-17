# frozen_string_literal: true

module Automations
  class TeamEmailDeliveryWorker
    include Sidekiq::Worker
    sidekiq_options queue: :mailers, retry: 3

    def perform(template_id, user_id, conversation_id, account_id)
      account = Account.find_by(id: account_id)
      return unless account

      account.with_shard do
        template = account.email_templates.find_by(id: template_id)
        user = User.find_by(id: user_id)
        conversation = account.conversations.find_by(id: conversation_id)

        return unless template && user && conversation

        inbox = conversation.inbox
        
        # Prepare Liquid context
        liquid_vars = {
          "user"     => { "name" => user.name, "email" => user.email },
          "customer" => { "name" => conversation.customers.first&.name },
          "agent"    => { "name" => conversation.assignee&.name, "email" => conversation.assignee&.email },
          "account"  => { "name" => account.name },
          "inbox"    => { "name" => inbox.name }
        }

        # Render content
        rendered_subject = if template.respond_to?(:render_subject) && template.subject.present?
                             template.render_subject(liquid_vars)
                           else
                             render_template(template.try(:subject), liquid_vars)
                           end

        rendered_body = if template.respond_to?(:render_body) && template.body.present?
                          template.render_body(liquid_vars)
                        else
                          render_template(template.try(:body) || template.try(:html_content), liquid_vars)
                        end

        # Dispatch the email directly via SystemMailer (internal team notifications do not create public conversation messages)
        SystemMailer.custom_email(
          to: user.email, 
          subject: rendered_subject, 
          body: rendered_body
        ).deliver_later
      end
    end

    private

    def render_template(content, vars)
      return "" if content.blank?
      Liquid::Template.parse(content).render(vars)
    rescue StandardError => e
      Rails.logger.error("[Automations::TeamEmailDeliveryWorker] Error rendering template: #{e.message}")
      content
    end
  end
end
