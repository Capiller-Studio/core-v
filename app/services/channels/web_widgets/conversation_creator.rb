# frozen_string_literal: true

module Channels
  module WebWidgets
    class ConversationCreator < ApplicationService
      attr_accessor :inbox, :web_widget_channel, :customer, :account,
                    :conversation, :contact_params, :content

      def initialize(web_widget_channel:, contact_params:, content:, account: nil)
        self.web_widget_channel = web_widget_channel
        self.contact_params     = contact_params
        self.content            = content
        self.account            = account || web_widget_channel.account
      end

      def call
        find_inbox

        ActiveRecord::Base.transaction do
          find_or_create_customer
          find_or_create_conversation
          create_message
        end

        conversation
      end

      private

      def find_inbox
        self.inbox = web_widget_channel.inboxes.first
      end

      def find_or_create_customer
        self.customer = Customers::CustomerCreator.call(
          account: account,
          inbox: inbox,
          external_id: contact_params[:external_id],
          email: contact_params[:email],
          params: contact_params.slice(:name, :first_name, :last_name, :avatar_url)
        )
      end

      def find_or_create_conversation
        find_conversation || create_conversation
        find_or_create_conversation_member
      end

      def find_conversation
        self.conversation = customer.conversations.where(inbox: inbox).find_by(account: account)
      end

      def create_conversation
        self.conversation = account.conversations.create!(
          inbox: inbox,
          source: :web_widget,
          identifier: SecureRandom.uuid,
          data: {}
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
          content: content
        )
      end
    end
  end
end
