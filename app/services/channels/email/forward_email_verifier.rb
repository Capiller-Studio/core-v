# frozen_string_literal: true

module Channels
  module Email
    class ForwardEmailVerifier < ApplicationService
      attr_reader :email_channel

      def initialize(email_channel)
        @email_channel = email_channel
      end

      def call
        return false if @email_channel.email.blank?

        # Generate a new token if one doesn't exist
        @email_channel.regenerate_forward_email_token
        @email_channel.forwarding_verified_at = nil
        @email_channel.save!(validate: false)

        # Send verification email via SystemMailer
        SystemMailer.forward_email_verification(@email_channel).deliver_later
        
        true
      rescue StandardError => e
        Rails.logger.error("ForwardEmailVerifier failed for Channel::Email##{@email_channel.id}: #{e.message}")
        false
      end
    end
  end
end
