# frozen_string_literal: true

require 'health_monitor_rfc/configuration'
require 'health_monitor_rfc/version'

module HealthMonitorRfc
  STATUSES = {
    ok: 'pass',
    error: 'fail',
    warn: 'warn',
    pass: 'pass',
    fail: 'fail',
    up: 'pass',
    down: 'fail'
  }.freeze

  HTPP_RESPONSE_PATTERNS = {
    ok: /^[2,3]\d\d/, # 2xx or 3xx
    error: /^[4,5]\d\d/, # 4xx, 5xx
    warn: /^[2,3]\d\d/ # 2xx or 3xx
  }.freeze

  extend self

  attr_accessor :configuration

  def configure
    self.configuration ||= Configuration.new

    yield configuration if block_given?
  end

  def check(request: nil, params: {})
    @status = STATUSES[:ok]
    @output = []
    @results = checks(request, params)
    {
      httpResponse: http_response,
      status: @status,
      serviceId: HealthMonitorRfc.name, # unique identifier of the service, in the application scope
      version: HealthMonitorRfc::API_VERSION,
      releaseId: HealthMonitorRfc::VERSION,
      description: 'Service to monitor the current health state of the application and its core components',
      notes: nil,
      links: {
        source: 'https://github.com/asped/health-monitor-rails-rfc'
      },
      output: @output.presence&.join(' '),
      checks: @results
    }.compact
  end

  private

  def checks(request, params)
    providers = configuration.providers
    if params[:providers].present?
      providers = providers.select { |provider| params[:providers].include?(provider.provider_name.downcase) }
    end
    all = []
    providers.each do |provider|
      all += [provider_result(provider, request)].flatten
    end
    all.map(&:flatten).collect.to_h
  end

  def http_response
    return :service_unavailable if @status == STATUSES[:fail]

    :ok
  end

  # rubocop:disable Metrics/AbcSize
  def provider_result(provider, request)
    monitor = provider.new(request: request)
    monitor.check!
    if monitor.status == STATUSES[:fail]
      @status = STATUSES[:fail]
      @output << monitor.output
      configuration.error_callback.try(:call, StandardError.new(monitor.output))
    end
    @status = STATUSES[:warn] if monitor.status == STATUSES[:warn]

    monitor.result
  rescue StandardError => e
    configuration.error_callback.try(:call, e)
    {
      provider.provider_name => [{
        status: STATUSES[:fail],
        output: e.message
      }]
    }
  end
  # rubocop:enable Metrics/AbcSize
end

HealthMonitorRfc.configure
