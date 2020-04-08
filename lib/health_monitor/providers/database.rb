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
          @details.merge!({
            status: STATUTES[:error],
            output: e.message
          })
        end
        result
      end

      def add_details
        @details.merge!({
          componentType: :datastore,
          time: Time.now.to_s(:iso8601),
          observedValue: 250,
          observedUnit: :ms,
          affectedEndpoints: [
            '/test/users/{userId}',
            '/test2/{customerId}/status',
            '/test3/shopping/{anything}'
          ],
          links: {
            :self => 'http://api.example.com/dbnode/dfd6cf2b/health',
            'http://key' => 'http://value'
          },

        })
      end
      def component_id
        ActiveRecord.object_id
      end

      def result
        [
          { "#{self.class.provider_name}:subComponent" => [@details] },
          { self.class.provider_name => [@details] }
        ]
      end
    end
  end
end
