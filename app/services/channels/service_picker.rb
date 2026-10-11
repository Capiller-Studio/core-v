# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.2.0
# Website: https://techbolic.com/

module Channels
  class ServicePicker < ApplicationService
    attr_accessor :channel, :inbox, :customer_inbox, :message, :conversation

    def initialize(conversation:, message:)
      self.conversation      = conversation
      self.inbox             = conversation.inbox
      # Priority: 
      # 1. Conversation's specific outbound channel (polymorphic)
      # 2. Inbox's default channel
      self.channel           = conversation.outbound_channel || conversation.inbox.channel
      self.customer_inbox    = find_customer_inbox
      self.message           = message
      
      # Persist the outbound channel used for historical tracking on the message
      message.update(outbound_channel: self.channel) if message.outgoing? && message.outbound_channel.nil?
    end

    def call
      deliver_message if channel.present?
    end

    private

    def deliver_message
      # Resolve service method based on channel class (e.g. Channel::Email -> channel_email_service)
      service_method = "channel_#{channel.class.name.demodulize.underscore}_service"
      
      if respond_to?(service_method, true)
        send(service_method)
      else
        Rails.logger.warn("ServicePicker: No delivery service implemented for #{channel.class.name} (method: #{service_method})")
      end
    end

    # --- Delivery Services ---

    def channel_email_service
      # Called from Messages::DeliveryWorker (background context)
      mail_message = ConversationReplyMailer.reply(conversation, message).deliver_now

      # Store the actual outbound Message-ID for threading future replies.
      # This lets the next reply's In-Reply-To/References chain back to our sent message.
      # rubocop:disable Rails/SkipsModelValidations
      outbound_message_id = mail_message.try(:message_id)
      if outbound_message_id.present?
        message.update_columns(external_id: outbound_message_id, status: :delivered)
      else
        message.update_column(:status, :delivered)
      end
      # rubocop:enable Rails/SkipsModelValidations
    rescue StandardError => e
      Rails.logger.error("ServicePicker Email Delivery Error: #{e.message}")
      # rubocop:disable Rails/SkipsModelValidations
      message.update_column(:status, :failed)
      # rubocop:enable Rails/SkipsModelValidations
      raise(e) # Re-raise to trigger Sidekiq retry if needed
    end

    def channel_whatsapp_service
      Channels::Whatsapp::CloudApi::MessageSender.call(
        whatsapp_channel: channel, 
        customer_inbox: customer_inbox,
        message: message
      )
    end

    def channel_facebook_page_service
      Channels::FacebookPages::MessageSender.call(
        facebook_page_channel: channel, 
        customer_inbox: customer_inbox,
        message: message
      )
    end

    def channel_instagram_service
      # Instagram message sending service
      Channels::Instagram::MessageSender.call(
        instagram_channel: channel,
        customer_inbox: customer_inbox,
        message: message
      )
    end

    def channel_short_message_service
      # Unified SMS delivery (Twilio, SignalWire, AWS SNS)
      Channels::ShortMessage::MessageSender.call(
        short_message_channel: channel,
        message: message
      )
    end

    def channel_web_widget_service
      # Live delivery handled via ActionCable real-time broadcast in Message callback.
      # Here we enqueue a worker to send an offline email reply if they have left the chat.
      Messages::OfflineReplyWorker.perform_in(5.minutes, message.account_id, message.id)
    end

    def channel_mobile_widget_service
      # Realtime delivery handled via CustomerChannel AnyCable broadcast.
      # Background push notification dispatched to iOS (APNs) and Android (FCM).
      Messages::MobilePushWorker.perform_async(message.account_id, message.id)

      # Optional offline email fallback if configured on the channel
      if channel.fallback_channel.present?
        Messages::OfflineReplyWorker.perform_in(15.minutes, message.account_id, message.id)
      end
    end

    def channel_custom_service
      return unless channel.webhook_url.present?

      payload = {
        event: "message.created",
        message: message.as_json(include: [:attachments, :sender]),
        conversation: conversation.as_json
      }

      delivery = Webhook::Delivery.create!(
        account_id: conversation.account_id,
        resource: channel,
        event_name: "message.created",
        endpoint_url: channel.webhook_url,
        request_payload: payload,
        status: :pending
      )

      Integrations::Webhooks::BroadcasterWorker.perform_async(conversation.account_id, delivery.id, 1)
    end

    def channel_contact_form_service
      # Contact form conversations route replies via email.
      # If the contact form has an outbound email channel configured, use it;
      # otherwise ConversationReplyMailer defaults to the system helpbolic relay.
      fallback = resolve_contact_form_email_channel

      begin
        mail_message = ConversationReplyMailer.reply(conversation, message, fallback).deliver_now

        # rubocop:disable Rails/SkipsModelValidations
        outbound_message_id = mail_message.try(:message_id)
        if outbound_message_id.present?
          message.update_columns(external_id: outbound_message_id, status: :delivered)
        else
          message.update_column(:status, :delivered)
        end
        # rubocop:enable Rails/SkipsModelValidations
      rescue StandardError => e
        Rails.logger.error("ServicePicker ContactForm Delivery Error: #{e.message}")
        # rubocop:disable Rails/SkipsModelValidations
        message.update_column(:status, :failed)
        # rubocop:enable Rails/SkipsModelValidations
        raise(e)
      end
    end

    # Resolve the configured outbound email channel for contact form reply delivery.
    # Priority:
    #   1. Conversation's outbound_channel (if email channel)
    #   2. Contact form channel's configured outbound_channel
    #   (No random fallback — if none configured, nil is passed so ConversationReplyMailer uses system relay)
    def resolve_contact_form_email_channel
      return conversation.outbound_channel if conversation.outbound_channel.is_a?(Channel::Email)

      form_channel = conversation.inbox&.channel
      if form_channel.is_a?(Channel::ContactForm) && form_channel.outbound_channel.present?
        return form_channel.outbound_channel
      end

      nil
    end

    def find_customer_inbox
      # Use detect on pre-loaded customer_inboxes to avoid any database queries here.
      # The DeliveryWorker eager loads conversation -> customer_inboxes
      conversation.customer_inboxes.detect { |ci| ci.inbox_id == inbox.id }
    end
  end
end
