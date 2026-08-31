# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

module Channels
  module Instagram
    class EditHandler < ApplicationService
      attr_accessor :channel, :account, :parsed_message, :mid

      def initialize(channel:, parsed_message:)
        self.channel        = channel
        self.account        = channel.account
        self.parsed_message = parsed_message
        self.mid            = parsed_message.edit_mid
      end

      def call
        return if mid.blank? || parsed_message.content.blank?

        lock_key = format(::RedisUtilities::Keys::MESSAGE_MUTATION_LOCK, account_id: account.id, external_id: mid)

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          ShardRecord.transaction do
            message = account.messages.where(inbox: channel.inboxes).find_by(external_id: mid)
            return unless message

            message.edit!(parsed_message.content)
          end
        end
      rescue StandardError => e
        Rails.logger.error("Instagram EditHandler error: #{e.message}")
        raise(e)
      end
    end
  end
end
