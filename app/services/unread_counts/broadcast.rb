# frozen_string_literal: true

module UnreadCounts
  class Broadcast < ApplicationService
    attr_accessor :member, :account_id

    def initialize(member:, account_id:)
      self.member = member
      self.account_id = account_id
    end

    def call
      tokens = connection_tokens
      return if tokens.empty?

      # Fetch current counts from Redis using the Current service
      counts = UnreadCounts::Current.call(member: member, account_id: account_id)

      # Offload to background worker for broadcast
      EventBroadcastWorker.perform_async(
        counts.to_json,
        "unread_counts.updated",
        tokens,
        account_id
      )
    end

    private

    def connection_tokens
      case member
      when User
        [member.connection_token]
      when Customer
        member.customer_inboxes.pluck(:connection_token)
      else
        []
      end
    end
  end
end
