# frozen_string_literal: true

class CsatDispatcherWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation && conversation.resolved?
    return unless conversation.account.feature_enabled?(:csat)

    conversation.account.with_shard do
      inbox = conversation.inbox
      customer = conversation.customers.first
      return unless customer
      return unless inbox.csat_survey_enabled?

      csat_survey = inbox.csat_survey
      # Don't send if a CSAT survey is already pending for this conversation
      return if Csat::SurveyResponse.exists?(conversation: conversation, status: :pending)

      message = nil

      ShardRecord.transaction do
        csat_response = Csat::SurveyResponse.create!(
          account: conversation.account,
          conversation: conversation,
          customer: customer,
          csat_survey: csat_survey,
          status: :pending
        )

        liquid_vars = {
          "customer" => { "name" => customer.name, "email" => customer.email },
          "agent"    => { "name" => conversation.assignee&.name, "email" => conversation.assignee&.email },
          "account"  => { "name" => conversation.account.name },
          "inbox"    => { "name" => inbox.name }
        }

        locale = conversation.locale || customer.locale || I18n.default_locale

        marketing_host = ENV.fetch("MARKETING_HOST", "deskbolic.com")
        protocol = Rails.env.development? || Rails.env.test? ? "http" : "https"
        survey_url = "#{protocol}://csat.#{marketing_host}/#{locale}/#{csat_response.global_routing_id}"

        I18n.with_locale(locale) do
          prompt_text = csat_survey&.render_prompt(liquid_vars)
          content = prompt_text.presence || I18n.t("csat.survey_prompt", default: "How would you rate the support you received?")
          content += "\n\n#{survey_url}"

          message = conversation.messages.create!(
            account: conversation.account,
            inbox: inbox,
            sender: conversation.account, # System message
            content: content,
            content_type: :csat,
            data: {
              csat_response_id: csat_response.id
            }
          )

          csat_response.update!(message: message)
        end
      end

      # Finally, dispatch the message to the customer via configured channels
      Messages::DeliveryWorker.perform_async(conversation.account_id, message.id) if message
    end
  end
end
