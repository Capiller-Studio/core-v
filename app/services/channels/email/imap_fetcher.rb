# frozen_string_literal: true

require "net/imap"

module Channels
  module Email
    class ImapFetcher < ApplicationService
      attr_accessor :email_channel

      def initialize(email_channel:)
        self.email_channel = email_channel
      end

      def call
        return unless email_channel.imap_enabled?

        fetch_and_process_emails
      end

      private

      def fetch_and_process_emails
        imap = connect
        return unless imap

        begin
          imap.select("INBOX")
          message_ids = imap.search(["UNSEEN"])

          message_ids.each do |msg_id|
            process_email(imap, msg_id)
          end
        ensure
          imap.logout
          imap.disconnect
        end
      end

      def connect
        config = email_channel.imap_config
        imap = Net::IMAP.new(
          config[:address],
          port: config[:port] || 993,
          ssl: config[:enable_ssl] != false
        )
        imap.login(config[:username], config[:password])
        imap
      rescue Net::IMAP::NoResponseError, Net::IMAP::ResponseError, SocketError, Errno::ECONNREFUSED => e
        Rails.logger.error("IMAP connection failed for Channel::Email##{email_channel.id}: #{e.message}")
        nil
      end

      def process_email(imap, msg_id)
        raw_email = imap.fetch(msg_id, "RFC822")&.first&.attr&.dig("RFC822")
        return unless raw_email

        mail = Mail.new(raw_email)

        # Skip if already processed (deduplication by Message-ID)
        return if message_already_processed?(mail)

        # Process via existing ConversationCreator pipeline
        Mailboxes::ConversationCreator.call(
          mail:,
          email_channel:
        )

        # Mark as seen on the IMAP server
        imap.store(msg_id, "+FLAGS", [:Seen])
      rescue StandardError => e
        Rails.logger.error("IMAP email processing failed for msg##{msg_id}: #{e.message}")
      end

      def message_already_processed?(mail)
        return false if mail.message_id.blank?

        email_channel.account.messages.exists?(external_id: mail.message_id)
      end
    end
  end
end
