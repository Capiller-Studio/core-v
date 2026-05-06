# frozen_string_literal: true

module Messages
  class ContactFormDeliveryWorker
    include Sidekiq::Worker
    sidekiq_options queue: :mailers, retry: 3

    def perform(message_id)
      message = Message.find_by(id: message_id)
      return unless message

      # Only send outbound messages from users (agents) to the customer
      return unless message.outgoing?
      return unless message.source == "help_center"

      ContactFormMailer.reply_message(message).deliver_now

      # rubocop:disable Rails/SkipsModelValidations
      message.update_column(:status, :delivered)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
