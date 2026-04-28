# frozen_string_literal: true

module Channels
  module WebWidgets
    class MessageCreator < ApplicationService
      attr_reader :account, :inbox, :conversation, :sender, :content, :message

      def initialize(account:, inbox:, conversation:, sender:, content:)
        @account = account
        @inbox = inbox
        @conversation = conversation
        @sender = sender
        @content = content
      end

      def call
        ActiveRecord::Base.transaction do
          create_message
        end

        message
      end

      private

      def create_message
        @message = conversation.messages.create!(
          account: account,
          sender: sender,
          content: content,
          inbox: inbox,
          source: :web_widget,
          data: {}
        )
      end
    end
  end
end
