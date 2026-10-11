# frozen_string_literal: true

module PushNotifications
  class MobileDispatcher < ApplicationService
    attr_reader :message, :conversation, :inbox, :channel, :account

    def initialize(message:)
      @message      = message
      @conversation = message.conversation
      @inbox        = message.inbox
      @channel      = @inbox.channel
      @account      = message.account
    end

    def call
      return unless eligible_for_push?

      customer = resolve_customer
      return unless customer

      # Suppress push notifications if customer is currently active in the mobile app
      return if ::Utilities::ActivityHelpers.activity?(account.id, "Customer", customer.id)

      devices = customer.customer_devices.where(inbox: inbox, status: :active)
      return if devices.empty?

      unread_count = calculate_unread_count(customer)
      payload = build_payload(unread_count)

      devices.find_each do |device|
        dispatch_to_device(device, payload)
      end
    end

    private

    def eligible_for_push?
      return false unless message.outgoing?
      return false unless message.global?
      return false unless channel.is_a?(Channel::MobileWidget)
      return false unless channel.push_enabled?

      true
    end

    def resolve_customer
      # Prefer direct conversation member or customer inbox customer
      conversation.conversation_members.detect { |cm| cm.member_type == "Customer" }&.member ||
        conversation.customer_inboxes.first&.customer
    end

    def calculate_unread_count(customer)
      counts = UnreadCounts::Current.call(member: customer, account_id: account.id)
      counts.dig(:inboxes, inbox.id.to_s).to_i
    rescue StandardError
      1
    end

    def build_payload(unread_count)
      sender_name = message.sender&.try(:name).presence || channel.name

      body_text = if channel.configurations&.dig("push_preview_mode") == "hidden"
                    "You have a new message"
                  else
                    message.content.to_s.strip.truncate(140)
                  end

      body_text = "Sent an attachment" if body_text.blank? && message.attachments.any?

      {
        title: sender_name,
        body: body_text,
        badge: [unread_count, 1].max,
        data: {
          conversation_id: conversation.id.to_s,
          inbox_id: inbox.id.to_s,
          message_id: message.id.to_s,
          type: "message"
        }
      }
    end

    def dispatch_to_device(device, payload)
      case device.push_provider.to_sym
      when :apns
        ApnsSender.call(channel: channel, device: device, payload: payload)
      when :fcm
        FcmSender.call(channel: channel, device: device, payload: payload)
      end
    rescue StandardError => e
      Rails.logger.error("[PushNotifications::MobileDispatcher] Failed sending push to device #{device.id}: #{e.message}")
    end
  end
end
