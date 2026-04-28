# frozen_string_literal: true

module Core
  class Engine < ::Rails::Engine
    initializer "core.append_migrations" do |app|
      unless app.root.to_s.match(root.to_s)
        app.config.paths["db/migrate"].concat([
          root.join("db/migrate").to_s,
        ])
      end
    end

    config.autoload_paths << config.root.join("lib")

    config.i18n.available_locales = %i[en de es fr ur hi ar zh]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true

    config.middleware.insert_before(0, Rack::Deflater)

    config.active_storage.routes_prefix = "/secure_storage"
  end
end
