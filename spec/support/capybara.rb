# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara/rails'
require 'capybara-screenshot/rspec'

Capybara.app = HealthMonitorRfc::Engine

RSpec.configure do |config|
  config.include HealthMonitorRfc::Engine.routes.url_helpers
end
