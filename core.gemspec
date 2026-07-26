require_relative "lib/core/version"

Gem::Specification.new do |spec|
  spec.name        = "core"
  spec.version     = Core::VERSION
  spec.authors     = [ "TECHBOLIC SOLUTIONS (PRIVATE) LIMITED" ]
  spec.email       = [ "info@techbolic.com" ]
  spec.homepage    = "https://techbolic.com/"
  spec.summary     = "Deskbolic Shared backend"
  spec.description = "Deskbolic Shared backend"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 4.0.6"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://techbolic.com/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/deskbolic/core.git"
  spec.metadata["changelog_uri"] = "https://github.com/deskbolic/core.git"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.3"
  spec.add_dependency "redis", ">= 4.2.5"
  spec.add_dependency 'image_processing'
  spec.add_dependency 'active_storage_validations'
  spec.add_dependency "aws-sdk-s3"
  spec.add_dependency 'sidekiq'

  # For Authentication
  spec.add_dependency 'devise'
  spec.add_dependency 'omniauth-facebook'
  spec.add_dependency 'omniauth-rails_csrf_protection'

  spec.add_dependency 'ancestry'

  # Search
  spec.add_dependency 'searchkick'
  spec.add_dependency 'elasticsearch'

  # JSON Optimization
  spec.add_dependency 'oj'

  # Countries and States data
  spec.add_dependency 'carmen'

  # locating ip address
  spec.add_dependency 'maxmind-geoip2'

  spec.add_dependency 'httparty'
  spec.add_dependency 'typhoeus'

  # Cryptography
  spec.add_dependency 'openssl'

  # bitwise features flag
  spec.add_dependency 'flag_shih_tzu'

  # --- Shared Stack dependencies moved from Gemfile ---
  spec.add_dependency 'liquid'
  spec.add_dependency 'anycable-rails'
  spec.add_dependency 'pundit'
  spec.add_dependency 'stringex'
  spec.add_dependency 'money'
  spec.add_dependency 'prawn', '>= 2.5.0'
  spec.add_dependency 'prawn-table'
  spec.add_dependency 'inline_svg'
  spec.add_dependency 'groupdate'
  spec.add_dependency 'pagy', '~> 6.2'
  spec.add_dependency 'facebook-messenger'
  spec.add_dependency 'koala'
  spec.add_dependency 'down'
  spec.add_dependency 'rack-attack'
  spec.add_dependency 'twilio-ruby'
  spec.add_dependency 'signalwire'
  spec.add_dependency 'aws-sdk-sns'
  spec.add_dependency 'mrml'
  spec.add_dependency 'stripe'
  spec.add_dependency 'email_reply_parser'
  spec.add_dependency 'webpush'
  # Development/Test tools for core engine development only
  spec.add_development_dependency 'dotenv-rails'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-rails'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'database_cleaner-active_record'
  spec.add_development_dependency 'ffaker'
  spec.add_development_dependency 'annotate'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'bullet'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rails'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-thread_safety'
  spec.add_development_dependency 'rubocop-capybara'
  spec.add_development_dependency 'rubocop-rails-omakase'
end
