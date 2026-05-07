# frozen_string_literal: true

module Messages
  class EmailDeliveryWorker
    include Sidekiq::Worker
    sidekiq_options queue: :mailers, retry: 3

    def perform(message_id)
      message = Message.find_by(id: message_id)
      return unless message
      return unless message.outgoing?

      # We call the ConversationReplyMailer from the deskbolic app
      # This works because both core and deskbolic are part of the same Rails environment
      ConversationReplyMailer.reply(message.conversation, message).deliver_now

      # rubocop:disable Rails/SkipsModelValidations
      message.update_column(:status, :delivered)
      # rubocop:enable Rails/SkipsModelValidations
    rescue StandardError => e
      Rails.logger.error "EmailDeliveryWorker Error: #{e.message}"
      # rubocop:disable Rails/SkipsModelValidations
      message.update_column(:status, :failed) if message
      # rubocop:enable Rails/SkipsModelValidations
      raise e
    end
  end
end
