# frozen_string_literal: true

module Channels
  module WebWidgets
    class IdentityVerifier < ApplicationService
      attr_reader :widget, :identifier, :signature

      def initialize(widget:, identifier:, signature:)
        @widget = widget
        @identifier = identifier
        @signature = signature
      end

      def call
        return false if signature.blank?

        expected_signature = OpenSSL::HMAC.hexdigest(
          'sha256',
          widget.hmac_token,
          identifier.to_s
        )

        ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
      end
    end
  end
end
