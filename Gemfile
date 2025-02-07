# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in core.gemspec.
gemspec

gem "puma"

gem "pg"

gem "propshaft"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"


# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Template parsing
gem 'liquid'

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.2.5"

gem "anycable-rails"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variant
gem 'image_processing'

# Active Storage validations
gem 'active_storage_validations'

# For Active Storage S3 storage
gem "aws-sdk-s3", require: false

# Background jobs processing
gem 'sidekiq'

# Cron Jobs
gem 'whenever', require: false

# For Authentication
gem 'devise'
gem 'omniauth-facebook'
gem 'omniauth-rails_csrf_protection'

gem 'ancestry'

# Search
gem 'searchkick'

# JSON Optimization
gem 'oj'

# Persistent HTTP Connections
gem 'typhoeus'

# Authorization
gem 'pundit'

# Extensions to ruby string class
gem 'stringex'

# Money and currency conversion utilities
gem 'money'

# Pdf
gem 'prawn'
gem 'prawn-table'

# svg-inline
gem 'inline_svg'

# Group by date query support
gem 'groupdate'

# Models localization
gem 'mobility', '~> 1.3.0.rc1'

# Channels
gem 'facebook-messenger'
gem 'koala'

# For downloading files
gem 'down'

# Countries and States data
gem 'carmen'

# Security
gem 'rack-attack'

# locating ip address
gem 'maxmind-geoip2'

gem 'httparty'

# Cryptography
gem 'openssl'

# bitwise features flag
gem 'flag_shih_tzu'



group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  # gem "debug", platforms: %i[ mri windows ]

  gem 'pry'
  gem 'pry-rails' # use pry for Rails console
  gem 'awesome_print'

  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-thread_safety', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-capybara', require: false

  gem 'factory_bot_rails'
  gem 'ffaker'
end

group :development do
  gem 'bullet'
  gem 'annotate'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem 'shoulda', '~> 4.0'
end
