# frozen_string_literal: true

module Messages
  class OfflineReplyWorker
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 3

    def perform(account_id, message_id)
      account = Account.find_by(id: account_id)
      return unless account

      account.with_shard do
        msg = Message.find_by(id: message_id)
        return unless msg
        return if msg.deleted?
        return if msg.incoming?
        return if msg.personal?
        return if msg.read?
        return if msg.external_id.present?

        conversation = msg.conversation
        return unless conversation

        customer = conversation.customers.first
        return if customer.nil? || customer.email.blank?

        # Don't send offline emails if the customer is currently online/active in the widget
        return if ::Utilities::ActivityHelpers.activity?(account.id, "Customer", customer.id)

        channel = conversation.inbox.channel
        return unless channel.is_a?(Channel::WebWidget)

        # Fallback channel logic
        outbound = channel.fallback_channel
        
        # We deliver the email
        begin
          # Assuming ConversationReplyMailer handles the heavy lifting
          mail_message = ConversationReplyMailer.reply(conversation, msg, outbound).deliver_now
          
          # rubocop:disable Rails/SkipsModelValidations
          outbound_message_id = mail_message.try(:message_id)
          if outbound_message_id.present?
            msg.update_columns(external_id: outbound_message_id, status: :delivered)
          else
            msg.update_column(:status, :delivered)
          end
          # rubocop:enable Rails/SkipsModelValidations
        rescue StandardError => e
          Rails.logger.error("OfflineReplyWorker Delivery Error: #{e.message}")
          # rubocop:disable Rails/SkipsModelValidations
          msg.update_column(:status, :failed)
          # rubocop:enable Rails/SkipsModelValidations
          raise(e)
        end
      end
    end
  end
end
