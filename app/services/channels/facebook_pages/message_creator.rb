# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module FacebookPages
    class MessageCreator < ApplicationService
      SUPPORTED_ATTACHMENT_TYPES = %w[
        image
        video
        audio
        file
        share
        story_mention
        location
        fallback
      ].freeze
      attr_accessor :parsed_message, :account, :inbox, :sender,
                    :conversation, :message, :facebook_page_channel

      def initialize(parsed_message:, account:, inbox:, sender:, conversation:, facebook_page_channel:)
        self.parsed_message        = parsed_message
        self.inbox                 = inbox
        self.sender                = sender
        self.account               = account
        self.conversation          = conversation
        self.facebook_page_channel = facebook_page_channel
      end

      def call
        # TODO: Important -> Use correct shard based on current-account

        ShardRecord.transaction do
          unless find_message
            create_message
            process_attachments
          end
        end
        message
      end

      private

      def create_message
        # TODO: Convert external id to Array
        self.message = conversation.messages.create!(
          account:,
          sender:,
          content: parsed_message.content,
          inbox:,
          external_id: parsed_message.mid,
          external_reply_to_id: parsed_message.reply_to_mid,
          data: {}
        )
      end

      def find_message
        self.message = conversation.messages.find_by(external_id: parsed_message.mid)
      end

      def process_attachments
        parsed_message.attachments.to_a.each do |attachment|
          process_attachment(attachment)
        end
      end

      # TODO: WIP
      def supported_attachment?(attachment)
        # TODO: validate attachment type -> attachment["type"]
        # [image, audio, video, file, template, fallback]
        SUPPORTED_ATTACHMENT_TYPES.include?(attachment["type"])
      end

      def process_attachment(attachment)
        attachment_type = attachment["type"].to_s

        if %w[image video audio file share story_mention].include?(attachment_type)
          process_file_attachment(attachment, attachment_type)
        elsif [ "location" ].include?(attachment_type)
          process_location_attachment(attachment, attachment_type)
        elsif [ "fallback" ].include?(attachment_type)
          process_fallback_attachment(attachment, attachment_type)
        end
      end

      def process_file_attachment(attachment, attachment_type)
        url = attachment.dig("payload", "url")
        tempfile = download_file(url)
        file_attachment = message.attachments.create!(
          remote_url: url,
          account:,
          attachment_type: parse_attachment_type(attachment_type, tempfile)
        )
        attach_file(file_attachment, tempfile) if tempfile
        process_story_attachment(file_attachment) if file_attachment.attachment_type == "story_mention"
      end

      def process_location_attachment(attachment, attachment_type)
        location_attachment = message.attachments.create!(
          remote_url: attachment["url"],
          latitude: attachment.dig("payload", "coordinates", "lat"),
          longitude: attachment.dig("payload", "coordinates", "long"),
          alt_title: attachment["title"],
          account:,
          attachment_type:
        )
        attach_file(location_attachment)
      end

      def process_fallback_attachment(attachment, attachment_type)
        fallback_attachment = message.attachments.create!(
          remote_url: attachment["url"],
          alt_title: attachment["title"],
          account:,
          attachment_type:
        )
        attach_file(fallback_attachment)
      end

      def attach_file(attachment, tempfile = nil)
        return if attachment.remote_url.blank?

        tempfile ||= download_file(attachment.remote_url)
        return unless tempfile

        attachment.file.attach(
          io: tempfile,
          filename: tempfile.respond_to?(:original_filename) ? tempfile.original_filename : File.basename(tempfile.path),
          content_type: tempfile.respond_to?(:content_type) ? tempfile.content_type : "application/octet-stream"
        )
      rescue StandardError => e
        Rails.logger.error("[FacebookPages::MessageCreator] Failed to attach file: #{e.message}")
      end

      def download_file(url)
        return if url.blank?

        Down.download(url)
      rescue StandardError => e
        Rails.logger.error("[FacebookPages::MessageCreator] Failed to download file from #{url}: #{e.message}")
        nil
      end

      def parse_attachment_type(attachment_type, tempfile)
        return attachment_type unless [ "share", "story_mention" ].include?(attachment_type)
        return attachment_type unless tempfile

        ::Utilities::AttachmentTypeHelpers.attachment_type(tempfile.content_type)
      end

      def fetch_story(external_id)
        client = Koala::Facebook::API.new(facebook_page_channel.access_token)
        client.get_object(external_id, fields: %w[story from])
      rescue Koala::Facebook::AuthenticationError => e
        facebook_page_channel.authorization_error!
        Rails.logger.error("[FacebookPages::MessageCreator] Auth error fetching story #{external_id}: #{e.message}")
        nil
      rescue Koala::Facebook::ClientError => e
        Rails.logger.warn("[FacebookPages::MessageCreator] Client error fetching story #{external_id}: #{e.message}")
        nil
      rescue StandardError => e
        Rails.logger.error("[FacebookPages::MessageCreator] Unexpected error fetching story #{external_id}: #{e.message}")
        nil
      end

      def process_story_attachment(_attachment)
        story = fetch_story(parsed_message.mid)

        return if story.blank?

        story.dig("story", "mention", "id")
        story.dig("from", "username")

        # TODO: Handle stories
      end
    end
  end
end
