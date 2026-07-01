# frozen_string_literal: true

module Notifiable
  extend ActiveSupport::Concern

  included do
    after_create_commit :deliver_notification
  end

  def read!
    update!(read_at: Time.current)
  end

  def read?
    read_at.present?
  end

  private

  def deliver_notification
    if event == "message_created"
      NotificationDeliveryWorker.perform_in(2.minutes, id, account_id)
    else
      NotificationDeliveryWorker.perform_async(id, account_id)
    end
  end
end
