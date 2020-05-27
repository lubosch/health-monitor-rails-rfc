# frozen_string_literal: true

require 'health_monitor_rfc/models/component'

module HealthMonitorRfc
  class Configuration
    PROVIDERS = %i[cache database delayed_job redis resque sidekiq].freeze

    attr_accessor :error_callback, :basic_auth_credentials, :environment_variables

    def initialize
      @custom_provider_classes = Set.new
      database
    end

    def no_database
      @default_providers.delete(HealthMonitorRfc::Providers::Database)
    end

    PROVIDERS.each do |provider_name|
      define_method provider_name do |&_block|
        require "health_monitor_rfc/providers/#{provider_name}"
        add_provider("HealthMonitorRfc::Providers::#{provider_name.to_s.titleize.delete(' ')}".constantize)
      end
    end

    def add_custom_provider(custom_provider_name)
      @custom_provider_classes << "HealthMonitorRfc::Providers::#{custom_provider_name.to_s.titleize.delete(' ')}"
    end

    def providers
      @default_providers + custom_providers
    end

    def custom_providers
      @custom_provider_classes.map do |provider_class|
        unless provider_class.constantize < HealthMonitorRfc::Providers::Base
          raise ArgumentError.new 'custom provider class must implement '\
            'HealthMonitorRfc::Providers::Base'
        end
        provider_class.constantize
      end
    end

    private

    def add_provider(provider_class)
      (@default_providers ||= Set.new) << provider_class

      provider_class
    end
  end
end
