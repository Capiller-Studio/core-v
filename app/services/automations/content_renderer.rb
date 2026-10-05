# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Automations
  # Renders Liquid variables inside automation/macro message & note content.
  #
  # Supported variables:
  #   {{ customer.name }}, {{ customer.first_name }}, {{ customer.email }}
  #   {{ agent.name }}, {{ agent.first_name }}, {{ agent.email }}
  #   {{ conversation.id }}, {{ conversation.identifier }}
  #   {{ inbox.name }}, {{ account.name }}
  #
  # "agent" resolves to the actor running the macro, falling back to the conversation assignee.
  # Rendering never raises — on template errors the raw content is returned unchanged.
  class ContentRenderer < ApplicationService
    attr_reader :content, :conversation, :account, :actor

    def initialize(content:, conversation:, account:, actor: nil)
      @content = content.to_s
      @conversation = conversation
      @account = account
      @actor = actor
    end

    def call
      return content unless content.include?("{{")

      Liquid::Template.parse(content).render(variables)
    rescue StandardError => e
      Rails.logger.warn("[Automations::ContentRenderer] Failed to render content: #{e.message}")
      content
    end

    private

    def variables
      customer = conversation.customers.first
      agent = actor.is_a?(User) ? actor : conversation.assignee

      {
        "customer" => person_vars(customer),
        "agent" => person_vars(agent),
        "conversation" => { "id" => conversation.id, "identifier" => conversation.identifier },
        "inbox" => { "name" => conversation.inbox&.name },
        "account" => { "name" => account&.name }
      }
    end

    def person_vars(person)
      return { "name" => "", "first_name" => "", "email" => "" } unless person

      full_name = person.try(:display_name).presence ||
                  [ person.try(:first_name), person.try(:last_name) ].compact_blank.join(" ").presence ||
                  person.try(:name).to_s

      {
        "name" => full_name,
        "first_name" => person.try(:first_name).presence || full_name.split.first.to_s,
        "email" => person.try(:email).to_s
      }
    end
  end
end
