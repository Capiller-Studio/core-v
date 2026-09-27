# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module SystemLogs
  class Logger < ApplicationService
    attr_reader :event_key, :level, :account, :account_id, :message, :payload, :metadata

    def initialize(event_key:, level: :info, account: nil, account_id: nil, message: nil, payload: {}, metadata: {})
      @event_key   = event_key
      @level       = level
      @account     = account
      @account_id  = account.try(:id) || account_id
      @message     = message
      @payload     = payload || {}
      @metadata    = metadata || {}
    end

    def call
      SystemLog.log_event(
        event_key,
        level:    level,
        account:  account || account_id,
        message:  message,
        payload:  payload,
        metadata: metadata.merge(request_context)
      )
    end

    private

    def request_context
      {
        remote_ip:  Current.try(:ip_address),
        user_agent: Current.try(:user_agent),
        request_id: Current.try(:request_id)
      }.compact
    end
  end
end
