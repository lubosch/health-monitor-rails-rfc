# frozen_string_literal: true

module HealthMonitor
  module Models
    class Component
      include ActiveModel::Validations

      COMPONENT_TYPES = %i[system datastore component].freeze
      COMPONENT_STATUSES = %w[pass fail warn].freeze
      URI_PATTERN = %r{\w+:(\/?\/?)[^\s]+}.freeze

      attr_accessor :status
      attr_accessor :component_id
      attr_accessor :component_type
      attr_accessor :observed_value
      attr_accessor :observed_unit
      attr_accessor :affected_endpoints
      attr_accessor :links
      attr_accessor :time
      attr_accessor :output
      attr_accessor :measurement_name

      validates_presence_of :status
      validates :status, inclusion: { in: COMPONENT_STATUSES, message: '%<value>s is not a valid status' }
      validates :component_type, inclusion: { in: COMPONENT_TYPES, message: '%<value>s is not a valid component type' }
      validates :output, presence: true, unless: -> { status == 'pass' }
      validates :affected_endpoints, absence: true, if: -> { status == 'pass' }
      validate :affected_endpoints_type
      validate :links_type

      def affected_endpoints_type
        return unless affected_endpoints.present?

        errors.add(:affected_endpoints, 'must be and an array of URIs') unless affected_endpoints.is_a?(Array)
        affected_endpoints.each do |link|
          errors.add(:affected_endpoints, "each value must be an URI. #{link} is not") unless link =~ URI_PATTERN
        end
      end

      def links_type
        return unless links.present?

        errors.add(:links, 'must be a Hash ') unless links.is_a?(Hash)
        links.each do |link|
          errors.add(:links, "each value must be an URI. #{link[1]} is not") unless link[1] =~ URI_PATTERN
        end
      end

      def initialize
        @status = HealthMonitor::STATUSES[:ok]
        @component_type = :system
        @time = Time.now.to_s(:iso8601)
        @measurement_name = nil
      end

      def result
        if invalid?
          @status = HealthMonitor::STATUSES[:warn]
          @output = [output, errors.full_messages.to_sentence].compact.join(', ')
        end

        {
          status: status,
          componentId: component_id,
          componentType: component_type,
          observedValue: observed_value,
          observedUnit: observed_unit,
          affectedEndpoints: affected_endpoints,
          links: links,
          time: time,
          output: output
        }.compact
      end
    end
  end
end
