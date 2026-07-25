# frozen_string_literal: true

module Channels
  module Custom
    class ConversationCreator < ApplicationService
      include Channels::Concerns::ConversationFinder

      attr_accessor :inbox, :custom_channel, :customer, :account,
                    :conversation, :customer_params, :content, :attachments,
                    :conversation_data, :external_id

      def initialize(custom_channel:, customer_params:, content: nil, attachments: [], account: nil, conversation_data: nil, external_id: nil)
        self.custom_channel    = custom_channel
        self.customer_params   = customer_params || {}
        self.content           = content
        self.attachments       = attachments || []
        self.account           = account || custom_channel.account
        self.conversation_data = conversation_data || {}
        self.external_id       = external_id
      end

      def call
        find_inbox

        ShardRecord.transaction do
          find_or_create_customer
          find_or_create_conversation
          create_message if content.present? || attachments.any?
        end

        conversation
      end

      private

      def find_inbox
        self.inbox = custom_channel.primary_inbox
      end

      def find_or_create_customer
        self.customer = Customers::CustomerCreator.call(
          account: account,
          inbox: inbox,
          external_id: customer_params[:external_id] || customer_params["external_id"],
          email: customer_params[:email] || customer_params["email"],
          params: customer_params.slice(:name, :first_name, :last_name, :avatar_url).to_h
        )
      end

      def find_or_create_conversation
        # If external_id is provided, we can look up an existing conversation directly.
        if external_id.present?
          self.conversation = account.conversations.find_by(external_id: external_id, inbox: inbox)
        end

        find_conversation unless conversation
        create_conversation unless conversation
        find_or_create_conversation_member
      end

      def find_conversation
        self.conversation = find_or_reopen_conversation(customer, inbox, account)
      end

      def create_conversation
        self.conversation = account.conversations.create!(
          inbox: inbox,
          source: :custom,
          title: conversation_data[:title].presence || conversation_data["title"],
          priority: conversation_data[:priority].presence || conversation_data["priority"] || "medium",
          data: conversation_data[:data] || conversation_data["data"] || {},
          external_id: external_id
        )
      end

      def find_or_create_conversation_member
        conversation.conversation_members.find_or_create_by!(conversation: conversation, member: customer, account: account)
      end

      def create_message
        MessageCreator.call(
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: customer,
          content: content,
          attachments: attachments
        )
      end
    end
  end
end
