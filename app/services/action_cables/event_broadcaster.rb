# frozen_string_literal: true

module ActionCables
  class EventBroadcaster < ApplicationService
    attr_accessor :data, :connection_tokens, :event, :body, :timestamp

    def initialize(data:, event:, connection_tokens:)
      self.data              = data
      self.event             = event
      self.connection_tokens = connection_tokens
      self.timestamp         = Time.now.to_i
    end

    def call
      configure_body
      broadcast

      true
    rescue StandardError => e
      Rails.logger.error("EventBroadcaster failed: #{e.message}")
      false
    end

    private

    def broadcast
      return if connection_tokens.blank?

      connection_tokens.each do |connection_token|
        next if connection_token.blank?

        ActionCable.server.broadcast(connection_token, body)
      end
    end

    def configure_body
      self.body = {
        event:,
        timestamp:,
        object: data
      }
    end
  end
end
