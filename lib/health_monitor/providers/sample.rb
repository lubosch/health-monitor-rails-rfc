# frozen_string_literal: true

require 'health_monitor/providers/base'

module HealthMonitor
  module Providers
    class Sample < Base
      private

      def perform_check
        # Check
        a = 1
        b = 1
        c = 2
        if a != c
          @component2.status = HealthMonitor::STATUSES[:error]
          @component2.output = 'There is something wrong with math'
        end
        a == b
      rescue StandardError => e
        @component.status = HealthMonitor::STATUSES[:error]
        @component.output = e.message
      end

      def add_details
        @component.component_id = '123456-XYZ'
        @component.component_type = :datastore
        @component.observed_value = 250
        @component.observed_unit = :ms
        @component.affected_endpoints = [
          'http://ex.com/test/users/{userId}',
          'http://ex.com//test2/{customerId}/status',
          'http://ex.com//test3/shopping/{anything}'
        ]
        @component.links = {
          self: 'http://api.example.com/dbnode/dfd6cf2b/health',
          info: 'http://some.more.info.page'
        }
        @component2 = @component.dup
        @component2.component_id = '456789'
        @component2.measurement_name = 'math'
        @components.push(@component2)
      end
    end
  end
end
