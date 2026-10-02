# frozen_string_literal: true

module Channels
  module WebWidgets
    class MessageCreator < ApplicationService
      attr_reader :account, :inbox, :conversation, :sender, :content, :attachments, :message

      def initialize(account:, inbox:, conversation:, sender:, content: nil, attachments: [])
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
          source: :web_widget,
          data: {}
        )
      end

      def create_attachments
        attachments.each do |file|
          if file.is_a?(Attachment)
            file.update!(resource: message)
          else
            attachment = message.attachments.build(
              account: account,
              attachment_type: detect_type(file)
            )
            attachment.file.attach(file)
            attachment.save!
          end
        end
      end

      def detect_type(file)
        return file.attachment_type if file.respond_to?(:attachment_type) && file.attachment_type.present?

        content_type = file.content_type.to_s if file.respond_to?(:content_type)
        filename = file.original_filename if file.respond_to?(:original_filename)
        filename ||= file.filename.to_s if file.respond_to?(:filename)

        if file.respond_to?(:file) && file.file.respond_to?(:attached?) && file.file.attached?
          content_type = file.file.blob.content_type if content_type.blank? && file.file.blob.respond_to?(:content_type)
          filename ||= file.file.blob.filename.to_s if file.file.blob.respond_to?(:filename)
        end

        file_path = begin
          file.path if file.respond_to?(:path)
        rescue StandardError
          nil
        end
        filename ||= File.basename(file_path) if file_path.present?

        if (content_type.blank? || content_type == "application/octet-stream") && filename.present?
          ext = File.extname(filename.to_s).downcase
          content_type = Rack::Mime.mime_type(ext, "") if ext.present?
        end
        content_type ||= ""

        case content_type
        when %r{\Aimage/} then :image
        when %r{\Avideo/} then :video
        when %r{\Aaudio/} then :audio
        else
          ext = File.extname(filename.to_s).downcase
          if %w[.mp3 .wav .ogg .m4a .aac .webm .flac .amr .opus].include?(ext)
            :audio
          elsif %w[.mp4 .mov .avi .mkv].include?(ext)
            :video
          elsif %w[.jpg .jpeg .png .gif .webp .bmp .svg].include?(ext)
            :image
          else
            :file
          end
        end
      end
    end
  end
end
