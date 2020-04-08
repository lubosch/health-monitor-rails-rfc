# frozen_string_literal: true

module HealthMonitor
  module Providers
    class Base
      attr_reader :request
      attr_accessor :configuration

      COMPONENT_TYPES = %i[system datastore component]

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
        @details = details
        return unless self.class.configurable?

        self.configuration = self.class.instance_variable_get('@global_configuration')
      end

      # @abstract
      def check!
        raise NotImplementedError
      end

      def self.configurable?
        configuration_class
      end

      # @abstract
      def self.configuration_class;
      end


      def details
        {
          status: HealthMonitor::STATUSES[:ok],
          componentId: component_id,
          componentType: component_type,
          #   observedValue: 250,
          #   observedUnit: :ms,
          #   affectedEndpoints: [
          #     '/test/users/{userId}',
          #     '/test2/{customerId}/status',
          #     '/test3/shopping/{anything}'
          #   ],
          #   links: {
          #     self => 'http://api.example.com/dbnode/dfd6cf2b/health',
          #     'http://key' => 'http://value'
          #   },
          #   time: Time.now.to_s(:iso8601)
        }
      end

      def component_id
        # is a unique identifier of an instance of a specific sub-component/dependency of a service
      end

      def component_type
        # SHOULD be present if componentName is present. pre-defined values include: component, datastore, system
        :system
      end

    end
  end
end
