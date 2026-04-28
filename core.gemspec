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

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://techbolic.com/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/deskbolic/core.git"
  spec.metadata["changelog_uri"] = "https://github.com/deskbolic/core.git"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.1"

  spec.add_dependency "redis", ">= 4.2.5"

  # Use Active Storage variant
  spec.add_dependency 'image_processing'


  # Active Storage validations
  spec.add_dependency 'active_storage_validations'

  # For Active Storage S3 storage
  spec.add_dependency "aws-sdk-s3"

  # Background jobs processing
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

  # Cryptography
  spec.add_dependency 'openssl'

  # bitwise features flag
  spec.add_dependency 'flag_shih_tzu'
end
