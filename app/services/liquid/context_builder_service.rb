# frozen_string_literal: true

module Liquid
  class ContextBuilderService < ApplicationService
    attr_reader :conversation, :agent, :message, :event, :template_type

    def initialize(conversation:, agent: nil, message: nil, event: nil, template_type: nil)
      @conversation = conversation
      @agent = agent
      @message = message
      @event = event
      @template_type = template_type # e.g., 'canned_response' or 'conversation_reply'
    end

    def call
      build_variables
    end

    private

    def build_variables
      customer = @conversation.customers.first

      vars = {
        "agent" => {
          "name" => @agent&.display_name || "Agent",
          "email" => @agent&.email
        },
        "customer" => {
          "name" => customer&.name,
          "email" => customer&.email,
          "full_phone_number" => customer&.full_phone_number
        },
        "conversation" => {
          "subject" => original_subject,
          "identifier" => @conversation.identifier
        },
        "inbox" => {
          "name" => @conversation.inbox&.name
        },
        "account" => {
          "name" => @conversation.account&.name
        }
      }

      if @message.present?
        vars["message"] = {
          "content" => @message.content
        }
      end

      if @event.present?
        vars["event"] = {
          "title" => @event.title,
          "description" => @event.description
        }
      end

      # Filter based on TEMPLATE_VARIABLES of the context
      filter_variables(vars)
    end

    def filter_variables(vars)
      # If no template_type is provided, return all generated vars
      return vars unless @template_type

      allowed = if @template_type == "canned_response"
                  CannedResponse::TEMPLATE_VARIABLES
                else
                  EmailTemplate::TEMPLATE_VARIABLES[@template_type]
                end

      return vars unless allowed

      filtered = {}
      allowed.each do |key, sub_keys|
        next unless vars.key?(key)

        if sub_keys.any?
          filtered[key] = vars[key].slice(*sub_keys)
        else
          filtered[key] = vars[key]
        end
      end

      filtered
    end

    def original_subject
      return @conversation.title if @conversation.title.present?

      first_message = @conversation.messages.order(created_at: :asc).first
      subject = first_message&.content&.truncate(40) || "Conversation ##{@conversation.identifier}"
      subject.delete("\n")
    end
  end
end
