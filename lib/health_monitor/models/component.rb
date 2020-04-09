module HealthMonitor
  module Models
    class Component
      COMPONENT_TYPES = %i[system datastore component]

      attr_accessor :status
      attr_accessor :component_id
      attr_accessor :component_type
      attr_accessor :observed_value
      attr_accessor :observed_unit
      attr_accessor :affected_endpoints
      attr_accessor :links
      attr_accessor :time
      attr_accessor :output
      attr_accessor :measurement_name

      def initialize
        @status = HealthMonitor::STATUSES[:ok]
        @component_type = :system
        @time = Time.now.to_s(:iso8601)
        @measurement_name = nil
      end

      def result
        {
          status: status,
          componentId: component_id,
          componentType: component_type,
          observedValue: observed_value,
          observedUnit: observed_unit,
          affectedEndpoints: affected_endpoints,
          links: links,
          time: time,
          output: output
        }.compact
      end
    end
  end
end
