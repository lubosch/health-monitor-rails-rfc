# frozen_string_literal: true

module HealthMonitor
  module Providers
    class Base
      attr_reader :request
      attr_reader :component
      attr_reader :result
      attr_accessor :configuration

      def self.provider_name
        @provider_name ||= name.demodulize
      end

      def self.configure
        return unless configurable?

        @global_configuration = configuration_class.new

        yield @global_configuration if block_given?
      end

      def initialize(request: nil)
        @request = request
        @component = HealthMonitor::Models::Component.new
        @components = [@component]

        return unless self.class.configurable?

        self.configuration = self.class.instance_variable_get('@global_configuration')
      end

      def check!
        add_details
        perform_check
        get_result
      end

      def self.configurable?
        configuration_class
      end

      def status
        check! if result.blank?
        statuses = @components.map(&:status)

        return HealthMonitor::STATUSES[:fail] if statuses.include?(HealthMonitor::STATUSES[:fail])
        return HealthMonitor::STATUSES[:warn] if statuses.include?(HealthMonitor::STATUSES[:warn])

        HealthMonitor::STATUSES[:ok]
      end

      # @abstract
      def self.configuration_class; end

      private

      # @abstract
      def perform_check
        raise NotImplementedError
      end

      # fill component details
      # @abstract
      def add_details
        raise NotImplementedError
      end

      def get_result
        @result = @components.map do |component|
          { component_name(component) => [component.result] }
        end
      end

      def component_name(component)
        [self.class.provider_name, component.measurement_name].compact.join(':')
      end
    end
  end
end
