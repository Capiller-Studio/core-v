# frozen_string_literal: true

module Automations
  module Actions
    class SendEmailToTeam < BaseAction
      def call
        require_conversation!

        template_id = params[:email_template_id]
        team_id = params[:team_id]
        raise "email_template_id is required" if template_id.blank?
        raise "team_id is required" if team_id.blank?

        template = account.email_templates.find(template_id)
        team = account.teams.find(team_id)

        # TODO: Send email to all team members with the rendered template
        # team.users.each do |user|
        #   Automations::EmailDeliveryWorker.perform_async(template.id, user.id, resource.id)
        # end
        Rails.logger.info("[Automations::SendEmailToTeam] Template #{template.id} → Team #{team.name}")
      end
    end
  end
end
