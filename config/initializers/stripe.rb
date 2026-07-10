# frozen_string_literal: true

require "stripe"

Stripe.api_key = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :secret_key)

# Pin to a specific API version to avoid breaking changes
Stripe.api_version = "2025-04-30.basil"
