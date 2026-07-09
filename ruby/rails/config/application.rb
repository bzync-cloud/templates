require_relative "boot"
require "rails"
require "action_controller/railtie"

module App
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    config.eager_load = ENV.fetch("RAILS_ENV", "development") == "production"
    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", ENV.fetch("SECRET_KEY", "change-me-in-production"))
  end
end
