# frozen_string_literal: true

require "stripe"

Stripe.api_key = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :secret_key)

# Pin to a specific API version to match webhook destination
Stripe.api_version = "2026-08-26.dahlia"
