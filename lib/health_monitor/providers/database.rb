# frozen_string_literal: true

require 'health_monitor/providers/base'

module HealthMonitor
  module Providers
    class Database < Base
      private

      def perform_check
        # Check connection to the DB:
        ActiveRecord::Migrator.current_version
      rescue Exception => e
        @component.status = HealthMonitor::STATUTES[:error]
        @component.output = e.message
      end

      def add_details
        @component.component_id = ActiveRecord.object_id
        @component.component_type = :jozkp
        @component.observed_value = 250
        @component.observed_unit = :ms
        @component.affected_endpoints = [
          '/test/users/{userId}',
          '/test2/{customerId}/status',
          '/test3/shopping/{anything}'
        ]
        @component.links = {
          :self => 'http://api.example.com/dbnode/dfd6cf2b/health',
          'http://key' => 'http://value'
        }
        @component2 = @component.dup
        @component2.component_id = '123'
        @component2.status = HealthMonitor::STATUSES[:error]
        @component2.measurement_name = 'test'
        @components.push(@component2)
      end
    end
  end
end
