# frozen_string_literal: true

module Affiliates
  module Payouts
    module Wise
      class Signer < ApplicationService
        attr_reader :token

        def initialize(token)
          @token = token
        end

        def call
          return nil if token.blank?

          private_key_pem = Rails.application.credentials.dig(Rails.env.to_sym, :wise, :private_key)
          raise("Wise Private Key not configured in credentials") if private_key_pem.blank?

          private_key = OpenSSL::PKey::RSA.new(private_key_pem)
          signature = private_key.sign(OpenSSL::Digest.new("SHA256"), token)

          Base64.strict_encode64(signature)
        end
      end
    end
  end
end
