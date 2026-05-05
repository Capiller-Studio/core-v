# frozen_string_literal: true

require "core/version"
require "core/engine"

# Functional dependencies moved to gemspec must be explicitly required
# so they are available in initializers and host applications.
require "devise"
require "sidekiq"
require "searchkick"
require "pundit"
require "httparty"
require "typhoeus"
require "mobility"
require "pagy"
require "facebook/messenger"
require "koala"
require "liquid"
require "anycable-rails"
require "money"
require "prawn"
require "prawn/table"
require "inline_svg"
require "groupdate"
require "carmen"
require "rack/attack"
require "elasticsearch"
require "ancestry"
require "stringex"
require "aws-sdk-s3"
require "aws-sdk-sns"
require "active_storage_validations"
require "flag_shih_tzu"
require "down"
require "oj"
require "maxmind/geoip2"
require "image_processing"
require "redis"
require "twilio-ruby"
require "signalwire"
require "dotenv/rails-now" if defined?(Dotenv)

module Core
  # Your code goes here...
end
