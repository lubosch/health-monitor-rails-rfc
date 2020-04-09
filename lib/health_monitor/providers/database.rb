# frozen_string_literal: true

require 'health_monitor/providers/base'

module HealthMonitor
  module Providers
    class DatabaseException < StandardError;
    end

    class Database < Base
      def check!
        add_details

        begin
          # Check connection to the DB:
          ActiveRecord::Migrator.current_version
        rescue Exception => e
          # raise DatabaseException.new(e.message)
          @component.status = HealthMonitor::STATUTES[:error]
          @component.output = e.message
        end
        result
      end

      def add_details
        @component.component_id = ActiveRecord.object_id
        @component.component_type = :datastore
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

      end

      def result
        [
          super,
          { "#{self.class.provider_name}:subComponent" => [@component2.result] },
        ]
      end
    end
  end
end
