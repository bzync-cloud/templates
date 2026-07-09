require_relative "boot"
require "rails"
require "action_controller/railtie"

module App
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
  end
end
