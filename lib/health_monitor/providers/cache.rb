# frozen_string_literal: true

require 'health_monitor/providers/base'

module HealthMonitor
  module Providers
    class CacheException < StandardError;
    end

    class Cache < Base
      def check!
        add_details

        begin
          time = Time.now.to_s
          Rails.cache.write(key, time)
          fetched = Rails.cache.read(key)

          if fetched != time
            @component2.observed_value = :false
            @component2.output = "different values (now: #{time}, fetched: #{fetched})"
          end

        rescue Exception => e
          # raise CacheException.new(e.message)
          @component.status = HealthMonitor::STATUTES[:error]
          @component.output = e.message
        end

        result
      end

      private

      def key
        @key ||= ['health', request.try(:remote_ip)].join(':')
      end

      def add_details
        @component.component_type = :datastore
        @component.component_id = Rails.cache.object_id
        @component.measurement_name = 'status'
        @component2 = @component.dup
        @component2.measurement_name = 'persistence'
        @component2.observed_unit = :boolean
        @component2.observed_value = :true
      end

       def result
         [
           super,
           { "#{self.class.provider_name}:#{@component2.measurement_name}"=> [@component2.result] }
         ]
       end
    end
  end
end
