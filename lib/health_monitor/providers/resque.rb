# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'resque'

module HealthMonitor
  module Providers
    class Resque < Base
      private

      def perform_check
        ::Resque.info
      rescue Exception => e
        @component.status = HealthMonitor::STATUSES[:error]
        @component.output = e.message
      end

      def add_details
        @component.component_id = Resque.object_id
        @component.component_type = :system
      end
    end
  end
end
