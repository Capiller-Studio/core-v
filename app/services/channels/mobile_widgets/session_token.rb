# frozen_string_literal: true

module Channels
  module MobileWidgets
    class SessionToken
      ALGORITHM = "HS256"
      DEFAULT_EXPIRY = 30.days
      PURPOSE = "mobile_widget_customer"

      class << self
        def encode(customer:, customer_inbox:, channel:, expiry: DEFAULT_EXPIRY)
          payload = {
            purpose: PURPOSE,
            account_id: channel.account_id,
            channel_id: channel.id,
            inbox_id: customer_inbox.inbox_id,
            customer_id: customer.id,
            cit: Digest::SHA256.hexdigest(customer_inbox.connection_token.to_s)[0..15],
            exp: expiry.from_now.to_i,
            iat: Time.current.to_i
          }

          JWT.encode(payload, channel.secret, ALGORITHM)
        end

        def decode(token, channel:)
          return nil if token.blank? || channel.blank?

          decoded, _header = JWT.decode(token, channel.secret, true, { algorithm: ALGORITHM })
          payload = decoded.with_indifferent_access

          return nil unless payload[:purpose] == PURPOSE
          return nil unless payload[:account_id].to_s == channel.account_id.to_s
          return nil unless payload[:channel_id].to_s == channel.id.to_s
          return nil unless payload[:customer_id].present?

          payload
        rescue JWT::ExpiredSignature, JWT::DecodeError
          nil
        end
      end
    end
  end
end
