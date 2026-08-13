# frozen_string_literal: true

require 'openai'

OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.openai_access_token || ENV.fetch("OPENAI_ACCESS_TOKEN", "sk-mock-key")
  config.log_errors = true
end
