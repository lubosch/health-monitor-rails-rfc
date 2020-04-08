# frozen_string_literal: true

require 'health_monitor/configuration'

module HealthMonitor
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
    @results = checks(request, params)

    {
      httpResponse: http_response,
      status: status,
      serviceId: HealthMonitor.name, # unique identifier of the service, in the application scope
      version: HealthMonitor::API_VERSION,
      releaseId: HealthMonitor::VERSION,
      description: 'Service to monitor the current health state of the application and its core components',
      notes: [],
      links: {
        'http://api.x.io/rel/thresholds7' => "http://api.x.io/rel/thresholds7",
        :self => "http://api.x.io/rel/thresholds2"
      },
      output: '', # should only be here if NOT PASS
      checks: @results
    }
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

    all.map do |provider|
      provider.flatten
    end.collect.to_h
  end

  def http_response
    return :service_unavailable if status == STATUSES[:fail]

    :ok
  end

  def status
    return STATUSES[:fail] if @results.each_value do |value|
      value.any? do |res|
        res[:status] == STATUSES[:fail]
      end
    end

    return STATUSES[:warn] if @results.each_value do |value|
      value.any? do |res|
        res[:status] == STATUSES[:warn]
      end
    end

    STATUSES[:ok]
  end

  def provider_result(provider, request)
    monitor = provider.new(request: request)
    monitor.check!

  rescue StandardError => e
    configuration.error_callback.try(:call, e)
    {
      provider.provider_name => [{
        status: STATUSES[:fail],
        output: e.message
      }]
    }.flatten
  end
end

HealthMonitor.configure
