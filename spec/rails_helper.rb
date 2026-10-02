require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../test/dummy/config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'shoulda/matchers'
require 'database_cleaner/active_record'
require 'factory_bot_rails'
require 'ffaker'
require 'timecop'

ActiveRecord::Encryption.configure(
  primary_key: "test_primary_key_for_rspec_testing",
  deterministic_key: "test_deterministic_key_for_rspec",
  key_derivation_salt: "test_key_derivation_salt_rspec"
)
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = false # Set to false to use DatabaseCleaner

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Searchkick.disable_callbacks if defined?(Searchkick)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :feature) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before do
    ActiveStorage::Current.url_options = { host: "example.com" }
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
