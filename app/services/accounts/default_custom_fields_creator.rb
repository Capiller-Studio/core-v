# frozen_string_literal: true

module Accounts
  class DefaultCustomFieldsCreator < ApplicationService
    attr_reader :account

    def initialize(account:)
      @account = account
    end

    def call
      create_default_fields
    end

    private

    def create_default_fields
      # Standard Contact Form Fields
      create_field("name", "Full Name", :customer, :text, true, "customer.name")
      create_field("email", "Email Address", :customer, :email, true, "customer.email")
      create_field("subject", "Subject", :conversation, :text, true, "conversation.title")
      create_field("message", "Message", :conversation, :textarea, true, "message.content")
      create_field("priority", "Priority", :conversation, :select, false, "conversation.priority", [
        { "value" => "low", "label" => "Low" },
        { "value" => "medium", "label" => "Medium" },
        { "value" => "high", "label" => "High" },
        { "value" => "urgent", "label" => "Urgent" }
      ])
    end

    def create_field(key, label, entity, type, required, mapped_to, options = [])
      field = account.custom_fields.find_or_initialize_by(key: key)
      field.update!(
        entity_type: entity,
        field_type: type,
        required: required,
        mapped_to: mapped_to,
        system_provided: true
      )

      translation = field.translations.find_or_initialize_by(locale: "en")
      translation.update!(
        label: label,
        options: options
      )
    end
  end
end
