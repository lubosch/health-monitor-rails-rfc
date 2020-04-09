# frozen_string_literal: true

require 'health_monitor/providers/base'
require 'delayed_job'

module HealthMonitor
  module Providers
    class DelayedJobException < StandardError;
    end

    class DelayedJob < Base
      class Configuration
        DEFAULT_QUEUES_SIZE = 100

        attr_accessor :queue_size

        def initialize
          @queue_size = DEFAULT_QUEUES_SIZE
        end
      end

      def check!
        add_details
        begin
          check_queue_size!
        rescue Exception => e
          # raise DelayedJobException.new(e.message)
          @component.output = e.message
          @component.status = HealthMonitor::STATUSES[:error]
        end
        result
      end

      private

      class << self
        private

        def configuration_class
          ::HealthMonitor::Providers::DelayedJob::Configuration
        end
      end

      def check_queue_size!
        size = job_class.count
        @component.observed_value = size

        return unless size > configuration.queue_size

        raise "queue size #{size} is greater than #{configuration.queue_size}"
      end

      def job_class
        @job_class ||= ::Delayed::Job
      end

      def add_details
        @component.component_type = :system
        @component.component_id = @job_class.object_id
        @component.observed_unit = :pcs
      end

    end
  end
end
