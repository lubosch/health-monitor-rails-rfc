# frozen_string_literal: true

require 'health_monitor/providers/base'

module HealthMonitor
  module Providers
    class Database < Base
      private

      def perform_check
        # Check connection to the DB:
        ActiveRecord::Base.connection.execute('select 1')
      rescue StandardError => e
        @component.status = HealthMonitor::STATUSES[:error]
        @component.output = e.message
      end

      def add_details
        @component.component_id = ActiveRecord.object_id
        @component.component_type = :datastore
        @component.observed_value = true
        @component.observed_unit = :boolean
      end
    end
  end
end
