# frozen_string_literal: true

module Channels
  module ContactForms
    class MessageCreator < ApplicationService
      attr_reader :account, :inbox, :conversation, :sender, :content, :attachments, :message

      def initialize(account:, inbox:, conversation:, sender:, content:, attachments: [])
        @account = account
        @inbox = inbox
        @conversation = conversation
        @sender = sender
        @content = content
        @attachments = attachments || []
      end

      def call
        ShardRecord.transaction do
          create_message
          create_attachments if attachments.any?
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
          source: :help_center,
          # message_type: :incoming,
          # private: false,
          data: {}
        )
      end

      def create_attachments
        attachments.each do |file|
          attachment = message.attachments.build(
            account: account,
            attachment_type: detect_type(file)
          )
          attachment.file.attach(file)
          attachment.save!
        end
      end

      def detect_type(file)
        content_type = file.content_type
        case content_type
        when /\Aimage\//  then :image
        when /\Avideo\//  then :video
        when /\Aaudio\//  then :audio
        else :file
        end
      end
    end
  end
end
