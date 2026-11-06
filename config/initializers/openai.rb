# frozen_string_literal: true

require 'openai'

OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.openai_access_token || ENV.fetch("OPENAI_ACCESS_TOKEN", "sk-mock-key")
  # ruby-openai appends v1, so this becomes https://omni.capiller.com/v1
  config.uri_base = ENV.fetch("OPENAI_URI_BASE", "https://omni.capiller.com/")
  config.log_errors = true
end
