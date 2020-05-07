# frozen_string_literal: true

require 'health_monitor_rfc/providers/base'
require 'resque'

module HealthMonitorRfc
  module Providers
    class Resque < Base
      private

      def perform_check
        ::Resque.info
      rescue StandardError => e
        component.status = HealthMonitorRfc::STATUSES[:error]
        component.output = e.message
      end

      def add_details
        component.component_id = Resque.object_id
        component.component_type = :system
      end
    end
  end
end
