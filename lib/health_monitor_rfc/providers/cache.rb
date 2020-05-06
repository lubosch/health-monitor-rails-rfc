# frozen_string_literal: true

require 'health_monitor_rfc/providers/base'

module HealthMonitorRfc
  module Providers
    class Cache < Base
      private

      def perform_check
        time = Time.now.to_s
        Rails.cache.write(key, time)
        fetched = Rails.cache.read(key)

        if fetched != time
          @component2.status = HealthMonitorRfc::STATUSES[:error]
          @component2.observed_value = false
          @component2.output = "different values (now: #{time}, fetched: #{fetched})"
        end
      rescue StandardError => e
        @component.status = HealthMonitorRfc::STATUSES[:error]
        @component.output = e.message
      end

      def key
        @key ||= ['health', request.try(:remote_ip)].join(':')
      end

      def add_details
        @component.component_type = :datastore
        @component.component_id = Rails.cache.object_id
        @component.measurement_name = 'status'

        @component2 = @component.dup
        @components.push(@component2)
        @component2.measurement_name = 'persistence'
        @component2.observed_unit = :boolean
        @component2.observed_value = true
      end
    end
  end
end
