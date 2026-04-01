# frozen_string_literal: true

module Messages
  class StatusUpdater < ApplicationService
    attr_accessor :account_id, :status, :external_ids, :watermark, :channel_class, :channel_id, :customer_external_id,
:error_code, :error_message

    def initialize(account_id:, status:, params: {})
      self.account_id = account_id
      self.status = status.to_sym
      self.external_ids = Array(params[:external_ids] || params[:external_id]).compact
      self.watermark = params[:watermark]
      self.channel_class = params[:channel_class]
      self.channel_id = params[:channel_id]
      self.customer_external_id = params[:customer_external_id]
      self.error_code = params[:error_code]
      self.error_message = params[:error_message]
      @conversation_id = params[:conversation_id]
    end

    def call
      update_by_external_ids if external_ids.present?
      update_by_watermark if watermark.present? && customer_external_id.present?
    end

    private

    def base_scope
      scope = Message.where(account_id: account_id).where.not(status: status)

      if channel_class.present? && channel_id.present?
        inbox = Inbox.find_by(channel_type: channel_class, channel_id: channel_id)
        scope = scope.where(inbox_id: inbox.id) if inbox
      end

      scope = scope.where(conversation_id: @conversation_id) if @conversation_id.present?
      scope
    end

    def update_by_external_ids
      scope = base_scope.where(external_id: external_ids)

      # Additional metadata logic if needed (like storing errors for failed)
      scope.update(status: status)
    end

    def update_by_watermark
      time_watermark = Time.zone.at(watermark / 1000.0)

      # Determine the customer
      customer = find_customer(customer_external_id)
      return unless customer

      # Find outgoing messages to this customer older than watermark
      customer.conversations.find_each do |conversation|
        base_scope.
          where(conversation_id: conversation.id).
          where(created_at: ..time_watermark).
          update(status: status)
      end
    end

    def find_customer(ext_id)
      Customer.find_by(account_id: account_id, external_id: ext_id)
    end
  end
end
