# frozen_string_literal: true

require 'health_monitor_rfc/providers/base'

module HealthMonitorRfc
  module Providers
    class Redis < Base
      class Configuration
        DEFAULT_URL = nil

        attr_accessor :url, :connection, :max_used_memory

        def initialize
          @url = DEFAULT_URL
        end
      end

      class << self
        private

        def configuration_class
          ::HealthMonitorRfc::Providers::Redis::Configuration
        end
      end

      def perform_check
        check_values!
        check_max_used_memory!
      rescue StandardError => e
        component.output = e.message
        component.status = HealthMonitorRfc::STATUSES[:error]
      ensure
        redis.close
      end

      private

      def check_values!
        time = Time.now.to_fs(:rfc2822)

        redis.set(key, time)
        fetched = redis.get(key)

        raise "different values (now: #{time}, fetched: #{fetched})" if fetched != time
      end

      def check_max_used_memory!
        return unless configuration.max_used_memory
        return if used_memory_mb <= configuration.max_used_memory

        component.observed_value = used_memory_mb
        component.observed_unit = 'MB'
        raise "#{used_memory_mb}Mb memory using is higher than #{configuration.max_used_memory}Mb maximum expected"
      end

      def key
        @key ||= ['health', request.try(:remote_ip)].join(':')
      end

      def redis
        @redis =
          if configuration.connection
            configuration.connection
          elsif configuration.url
            ::Redis.new(url: configuration.url)
          else
            ::Redis.new
          end
      end

      def bytes_to_megabytes(bytes)
        (bytes.to_f / 1024 / 1024).round
      end

      def used_memory_mb
        bytes_to_megabytes(redis.info['used_memory'])
      end

      def add_details
        component.component_type = :datastore
        component.component_id = redis.object_id
      end
    end
  end
end
