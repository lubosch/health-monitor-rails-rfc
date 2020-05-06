# frozen_string_literal: true

require 'spec_helper'
require 'timecop'
require './app/controllers/health_monitor_rfc/health_controller'

describe HealthMonitorRfc::HealthController, type: :controller do
  routes { HealthMonitorRfc::Engine.routes }

  let(:time) { Time.local(1990) }

  before do
    Timecop.freeze(time)
  end

  after do
    Timecop.return
  end

  describe 'basic authentication' do
    let(:username) { 'username' }
    let(:password) { 'password' }

    before do
      HealthMonitorRfc.configure do |config|
        config.basic_auth_credentials = { username: username, password: password }
        config.environment_variables = nil
      end
    end

    context 'valid credentials provided' do
      before do
        request.env['HTTP_AUTHORIZATION'] =
          ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
      end

      it 'succesfully checks' do
        expect {
          get :health, format: :json
        }.not_to raise_error

        expect(response).to be_ok
        expect(JSON.parse(response.body)).to include(
          'checks' => {
            'Database' => [hash_including(
              'status' => 'pass',
              'time' => time.to_s(:iso8601)
            )]
          },
          'status' => 'pass'
        )
      end

      context 'when filtering provider' do
        let(:params) do
          if Rails.version >= '5'
            { params: { providers: providers }, format: :json }
          else
            { providers: providers, format: :json }
          end
        end

        context 'multiple providers' do
          let(:providers) { %w[redis database] }
          it 'succesfully checks' do
            expect {
              get :health, params
            }.not_to raise_error

            expect(response).to be_ok
            expect(JSON.parse(response.body)).to include(
              'checks' => {
                'Database' => [hash_including(
                  'status' => 'pass',
                  'time' => time.to_s(:iso8601)
                )]
              },
              'status' => 'pass'
            )
          end
        end

        context 'single provider' do
          let(:providers) { %w[redis] }
          it 'return empty providers' do
            expect {
              get :health, params
            }.not_to raise_error

            expect(response).to be_ok
            expect(JSON.parse(response.body)).to include(
              'checks' => {},
              'status' => 'pass'
            )
          end
        end

        context 'unknown provider' do
          let(:providers) { %w[foo-bar!] }
          it 'returns empty providers' do
            expect {
              get :health, params
            }.not_to raise_error

            expect(response).to be_ok
            expect(JSON.parse(response.body)).to include(
              'checks' => {},
              'status' => 'pass'
            )
          end
        end
      end
    end
    context 'invalid credentials provided' do
      before do
        request.env['HTTP_AUTHORIZATION'] =
          ActionController::HttpAuthentication::Basic.encode_credentials('', '')
      end

      it 'fails' do
        expect {
          get :health, format: :json
        }.not_to raise_error

        expect(response).not_to be_ok
        expect(response.status).to eq(401)
      end
    end
  end

  describe 'environment variables' do
    let(:environment_variables) { { build_number: '12', git_sha: 'example_sha', status: 'fake_status' } }

    before do
      HealthMonitorRfc.configure do |config|
        config.basic_auth_credentials = nil
        config.environment_variables = environment_variables
      end
    end

    context 'valid environment variables synatx provided' do
      it 'succesfully checks and removes unpermitted env vars' do
        expect {
          get :health, format: :json
        }.not_to raise_error

        expect(response).to be_ok
        expect(JSON.parse(response.body)).to include(
          'checks' => {
            'Database' => [hash_including(
              'status' => 'pass',
              'time' => time.to_s(:iso8601)
            )]
          },
          'status' => 'pass',
          'build_number' => '12',
          'git_sha' => 'example_sha'
        )
      end
    end
  end

  describe '#health' do
    before do
      HealthMonitorRfc.configure do |config|
        config.basic_auth_credentials = nil
        config.environment_variables = nil
      end
    end

    context 'json rendering' do
      it 'succesfully checks' do
        expect {
          get :health, format: :json
        }.not_to raise_error

        expect(response).to be_ok
        expect(JSON.parse(response.body)).to include(
          'checks' => {
            'Database' => [hash_including(
              'status' => 'pass',
              'time' => time.to_s(:iso8601)
            )]
          },
          'status' => 'pass'
        )
        expect(JSON.parse(response.body)).to include('checks' => { 'Database' => [hash_excluding('output')] })
      end

      context 'failing' do
        before do
          Providers.stub_database_failure
        end

        it 'should fail' do
          expect {
            get :health, format: :json
          }.not_to raise_error

          expect(response).not_to be_ok
          expect(response.status).to eq(503)

          expect(JSON.parse(response.body)).to include(
            'checks' => {
              'Database' => [hash_including(
                'status' => 'fail',
                'time' => time.to_s(:iso8601),
                'output' => 'my db exception'
              )]
            },
            'status' => 'fail'
          )
        end
      end
    end

    context 'xml rendering' do
      it 'succesfully checks' do
        expect {
          get :health, format: :xml
        }.not_to raise_error

        expect(response).to be_ok
        expect(parse_xml(response)).to include(
          'checks' => {
            'Database' => [hash_including(
              'status' => 'pass',
              'time' => time.to_s(:iso8601)
            )]
          },
          'status' => 'pass'
        )
        expect(parse_xml(response)).to include('checks' => { 'Database' => [hash_excluding('output')] })
      end

      context 'failing' do
        before do
          Providers.stub_database_failure
        end

        it 'should fail' do
          expect {
            get :health, format: :xml
          }.not_to raise_error

          expect(response).not_to be_ok
          expect(response.status).to eq(503)
          expect(parse_xml(response)).to include(
            'checks' => {
              'Database' => [hash_including(
                'status' => 'fail',
                'output' => 'my db exception',
                'time' => time.to_s(:iso8601)
              )]
            },
            'status' => 'fail'
          )
        end
      end
    end
  end
end
