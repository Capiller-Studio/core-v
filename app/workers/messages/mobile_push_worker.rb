# frozen_string_literal: true

module Messages
  class MobilePushWorker
    include Sidekiq::Worker
    sidekiq_options queue: :mailers, retry: 2

    def perform(account_id, message_id)
      account = Account.find_by(id: account_id)
      return unless account

      account.with_shard do
        message = account.messages.includes(
          :inbox,
          :sender,
          :attachments,
          conversation: [:conversation_members, { customer_inboxes: :customer }, { inbox: :channel }]
        ).find_by(id: message_id)

        return unless message

        PushNotifications::MobileDispatcher.call(message: message)
      end
    end
  end
end
