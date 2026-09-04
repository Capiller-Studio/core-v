# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.3.0
# Website: https://techbolic.com/

module Messages
  class DeliveryWorker
    include Sidekiq::Worker
    sidekiq_options queue: :mailers, retry: 3

    def perform(account_id, message_ids)
      # 1. Resolve the account from the primary database
      account = Account.find_by(id: account_id)
      return unless account

      # 2. Switch to the correct shard for this account
      account.with_shard do
        ids = Array(message_ids).compact_blank
        return if ids.empty?

        # 3. Comprehensive eager loading to cover all delivery paths:
        # - attachments: used by all senders
        # - inbox: used to derive default channels
        # - inbox.channel: the actual delivery mechanism (polymorphic)
        # - conversation.outbound_channel: prioritized delivery mechanism (polymorphic)
        # - conversation.conversation_members: used to identify the customer
        # - conversation.customer_inboxes: used to get customer's channel-specific ID
        messages_by_id = account.messages.includes(
          :attachments,
          :inbox,
          { inbox: :channel },
          { conversation: [
            :outbound_channel,
            :conversation_members,
            { customer_inboxes: :customer }
          ] }
        ).where(id: ids).index_by(&:id)

        # 4. Deliver messages sequentially in the exact specified order
        ids.each do |message_id|
          message = messages_by_id[message_id]
          next unless message && message.outgoing?

          Channels::ServicePicker.call(
            conversation: message.conversation,
            message: message
          )
        end
      end
    end
  end
end
