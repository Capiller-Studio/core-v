# frozen_string_literal: true

module Channels
  module ContactForms
    class ConversationCreator < ApplicationService
      attr_accessor :inbox, :contact_form_channel, :customer, :account,
                    :conversation, :form_params, :attachments

      def initialize(contact_form_channel:, form_params:, attachments: [])
        self.contact_form_channel = contact_form_channel
        self.form_params          = form_params.to_h.with_indifferent_access
        self.attachments          = attachments || []
        self.account              = contact_form_channel.account
      end

      def call
        find_inbox

        ActiveRecord::Base.transaction do
          process_custom_fields
          find_or_create_customer
          create_conversation
          create_message if @message_content.present? || attachments.any?
        end

        send_confirmation_email if contact_form_channel.send_confirmation_email?

        conversation
      end

      private

      def find_inbox
        self.inbox = contact_form_channel.inboxes.first
      end

      def process_custom_fields
        @customer_data = {}
        @conversation_data = {}
        @message_content = ""

        # Map form_params based on CustomField definitions associated with this ContactForm
        custom_fields = contact_form_channel.custom_fields

        custom_fields.each do |field|
          value = form_params[field.key]
          next if value.blank?

          if field.mapped_to.present?
            map_to_internal_attribute(field, value)
          else
            store_in_jsonb_data(field, value)
          end
        end
      end

      def map_to_internal_attribute(field, value)
        case field.mapped_to
        when "customer.name"       then @customer_data["name"] = value
        when "customer.first_name" then @customer_data["first_name"] = value
        when "customer.last_name"  then @customer_data["last_name"] = value
        when "customer.email"      then @customer_data["email"] = value
        when "conversation.title"  then @conversation_data[:title] = value
        when "conversation.priority" then @conversation_data[:priority] = value
        when "message.content"     then @message_content = value
        end
      end

      def store_in_jsonb_data(field, value)
        case field.entity_type.to_sym
        when :customer
          @customer_data["data"] ||= {}
          @customer_data["data"][field.key] = value
        when :conversation, :contact_form
          @conversation_data["data"] ||= {}
          @conversation_data["data"][field.key] = value
        end
      end

      def find_or_create_customer
        # Contact forms might not always have an email if anonymous, but usually they do.
        email = @customer_data["email"]
        external_id = email || "anon-#{SecureRandom.hex(8)}"

        self.customer = Customers::CustomerCreator.call(
          account: account,
          inbox: inbox,
          external_id: external_id,
          email: email,
          params: @customer_data.slice("name", "first_name", "last_name", "data")
        )
      end

      def create_conversation
        self.conversation = account.conversations.create!(
          inbox: inbox,
          source: :help_center, # Source enum 8
          identifier: SecureRandom.uuid,
          title: @conversation_data[:title] || "New Contact Form Submission",
          priority: @conversation_data[:priority] || "medium",
          data: @conversation_data["data"] || {}
        )

        conversation.conversation_members.create!(member: customer, account: account)
      end

      def create_message
        Channels::ContactForms::MessageCreator.call(
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: customer,
          content: @message_content,
          attachments: attachments
        )
      end

      def send_confirmation_email
        ContactFormMailer.confirmation_email(conversation).deliver_later
      end
    end
  end
end
