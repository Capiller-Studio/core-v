# frozen_string_literal: true

module Channels
  module ShortMessage
    module Twilio
      class MessageCreator < ApplicationService
        attr_accessor :parsed_message, :account, :inbox, :sender,
                      :conversation, :message, :short_message_channel

        def initialize(parsed_message:, account:, inbox:, sender:, conversation:, short_message_channel:)
          self.parsed_message        = parsed_message
          self.inbox                 = inbox
          self.sender                = sender
          self.account               = account
          self.conversation          = conversation
          self.short_message_channel = short_message_channel
        end

        def call
          ActiveRecord::Base.transaction do
            unless find_message
              create_message
              process_attachments
            end
          end
          message
        end

        private

        def create_message
          self.message = conversation.messages.create!(
            account: account,
            sender: sender,
            content: parsed_message["Body"],
            inbox: inbox,
            external_id: parsed_message["MessageSid"],
            data: {}
          )
        end

        def find_message
          self.message = conversation.messages.find_by(external_id: parsed_message["MessageSid"])
        end

        def process_attachments
          num_media = parsed_message["NumMedia"].to_i
          return if num_media.zero?

          num_media.times do |i|
            url = parsed_message["MediaUrl#{i}"]
            content_type = parsed_message["MediaContentType#{i}"]
            next if url.blank?

            process_file_attachment(url, content_type)
          end
        end

        def process_file_attachment(url, content_type)
          attachment_type = Utilities::AttachmentTypeHelpers.attachment_type(content_type) rescue "file"

          file_attachment = message.attachments.create!(
            remote_url: url,
            account: account,
            attachment_type: attachment_type
          )
          
          Utilities::ActiveStorageDownloader.attach(
            record: file_attachment,
            attachment_name: :file,
            url: url
          )
        end
      end
    end
  end
end
