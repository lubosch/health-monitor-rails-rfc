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

          raise "different values (now: #{time}, fetched: #{fetched})" if fetched != time
        rescue Exception => e
          # raise CacheException.new(e.message)
          @details.merge!({
            status: STATUTES[:error],
            output: e.message
          })
        end

        result
      end

      private

      def key
        @key ||= ['health', request.try(:remote_ip)].join(':')
      end

      def add_details
        @details.merge!({
          componentType: :datastore,
          time: Time.now.to_s(:iso8601),
        })
      end

      def result
        { self.class.provider_name => [@details] }
      end
    end
  end
end
