# frozen_string_literal: true

module Webhooks
  class WebWidgetEventListenWorker < BaseMutexWorker
    def perform(webhook_id)
      webhook = Webhook::Incoming.find_by(id: webhook_id)
      return unless webhook

      begin
        route_params = webhook.route_params
        channel_id = route_params[:channel_id]
        account_id = route_params[:account_id]

        account = Account.find_by(id: account_id)
        return unless account

        account.with_shard do
          channel = Channel::WebWidget.find_by(id: channel_id, account_id: account_id)
          return unless channel_active?(channel)

          payload = webhook.payload.with_indifferent_access
          event_type = webhook.event_type

          Current.set(account: account) do
            Channels::WebWidget::EventListener.call(
              channel: channel,
              payload: payload,
              event_type: event_type
            )
          end
        end

        webhook.processed!
      rescue => e
        webhook.update!(status: :failed, error_message: "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        raise e
      end
    end

    private

    def channel_active?(channel)
      return false if channel.blank? || !channel.active? || !channel.account&.active?

      true
    end
  end
end
