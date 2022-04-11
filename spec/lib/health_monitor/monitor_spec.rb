# frozen_string_literal: true

require 'spec_helper'

describe HealthMonitorRfc do
  let(:time) { Time.local(1990) }

  before do
    HealthMonitorRfc.configuration = HealthMonitorRfc::Configuration.new

    Timecop.freeze(time)
  end

  let(:request) { test_request }

  after do
    Timecop.return
  end

  describe '#configure' do
    describe 'providers' do
      it 'configures a single provider' do
        expect {
          subject.configure(&:redis)
        }.to change { HealthMonitorRfc.configuration.providers }
          .to(Set.new([HealthMonitorRfc::Providers::Database, HealthMonitorRfc::Providers::Redis]))
      end

      it 'configures a single provider with custom configuration' do
        expect {
          subject.configure(&:redis).configure do |redis_config|
            redis_config.url = 'redis://user:pass@example.redis.com:90210/'
          end
        }.to change { HealthMonitorRfc.configuration.providers }
          .to(Set.new([HealthMonitorRfc::Providers::Database, HealthMonitorRfc::Providers::Redis]))
      end

      it 'configures a multiple providers' do
        expect {
          subject.configure do |config|
            config.redis
            config.sidekiq
          end
        }.to change { HealthMonitorRfc.configuration.providers }
          .to(Set.new([HealthMonitorRfc::Providers::Database, HealthMonitorRfc::Providers::Redis,
                 HealthMonitorRfc::Providers::Sidekiq]))
      end

      it 'configures multiple providers with custom configuration' do
        expect {
          subject.configure do |config|
            config.redis
            config.sidekiq.configure do |sidekiq_config|
              sidekiq_config.add_queue_configuration('critical', latency: 10.seconds, queue_size: 20)
            end
          end
        }.to change { HealthMonitorRfc.configuration.providers }
          .to(Set.new([HealthMonitorRfc::Providers::Database, HealthMonitorRfc::Providers::Redis,
                 HealthMonitorRfc::Providers::Sidekiq]))
      end

      it 'appends new providers' do
        expect {
          subject.configure(&:resque)
        }.to change { HealthMonitorRfc.configuration.providers }.to(Set.new([HealthMonitorRfc::Providers::Database,
          HealthMonitorRfc::Providers::Resque]))
      end
    end

    describe 'error_callback' do
      it 'configures' do
        error_callback = proc do
        end

        expect {
          subject.configure do |config|
            config.error_callback = error_callback
          end
        }.to change { HealthMonitorRfc.configuration.error_callback }.to(error_callback)
      end
    end

    describe 'basic_auth_credentials' do
      it 'configures' do
        expected = {
          username: 'username',
          password: 'password'
        }

        expect {
          subject.configure do |config|
            config.basic_auth_credentials = expected
          end
        }.to change { HealthMonitorRfc.configuration.basic_auth_credentials }.to(expected)
      end
    end
  end

  describe '#check' do
    context 'default providers' do
      it 'succesfully checks' do
        expect(subject.check(request: request)).to include(
          checks: {
            'Database' => [hash_including(
              status: 'pass',
              time: time.to_fs(:iso8601)
            )]
          },
          status: 'pass'
        )
      end
    end

    context 'db and redis providers' do
      before do
        subject.configure do |config|
          config.database
          config.redis
        end
      end

      it 'succesfully checks' do
        expect(subject.check(request: request)).to include(
          checks: {
            'Database' => [hash_including(
              status: 'pass',
              time: time.to_fs(:iso8601)
            )],
            'Redis' => [hash_including(
              status: 'pass',
              time: time.to_fs(:iso8601)
            )]
          },
          status: 'pass'
        )
      end

      context 'redis fails' do
        before do
          Providers.stub_redis_failure
        end

        it 'fails check' do
          expect(subject.check(request: request)).to include(
            checks: {
              'Database' => [hash_including(
                status: 'pass',
                time: time.to_fs(:iso8601)
              )],
              'Redis' => [hash_including(
                status: 'fail',
                output: "different values (now: #{time}, fetched: false)",
                time: time.to_fs(:iso8601)
              )]
            },
            status: 'fail'
          )
        end
      end

      context 'sidekiq fails' do
        before do
          Providers.stub_sidekiq_workers_failure
        end

        it 'succesfully checks' do
          expect(subject.check(request: request)).to include(
            checks: {
              'Database' => [hash_including(
                status: 'pass',
                time: time.to_fs(:iso8601)
              )],
              'Redis' => [hash_including(
                status: 'pass',
                time: time.to_fs(:iso8601)
              )]
            },
            status: 'pass'
          )
        end
      end
      context 'both redis and db fail' do
        before do
          Providers.stub_database_failure
          Providers.stub_redis_failure
        end

        it 'fails check' do
          expect(subject.check(request: request)).to include(
            checks: {
              'Database' => [hash_including(
                status: 'fail',
                output: 'my db exception',
                time: time.to_fs(:iso8601)
              )],
              'Redis' => [hash_including(
                status: 'fail',
                output: "different values (now: #{time}, fetched: false)",
                time: time.to_fs(:iso8601)
              )]
            },
            status: 'fail'
          )
        end
      end
    end

    context 'with error callback' do
      test = false

      let(:callback) do
        proc do |e|
          expect(e).to be_present
          expect(e).to be_is_a(Exception)
          expect(e.message).to eq('my db exception')
          test = true
        end
      end

      before do
        subject.configure do |config|
          config.database

          config.error_callback = callback
        end

        Providers.stub_database_failure
        Providers.stub_redis_failure
      end

      it 'calls error_callback' do
        expect(subject.check(request: request)).to include(
          checks: {
            'Database' => [hash_including(
              status: 'fail',
              output: 'my db exception',
              time: time.to_fs(:iso8601)
            )]
          },
          status: 'fail'
        )
        expect(test).to be_truthy
      end
    end
  end
end
