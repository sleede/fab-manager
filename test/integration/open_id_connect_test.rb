# frozen_string_literal: true

require 'test_helper'
require 'helpers/auth_provider_helper'

class OpenIdConnectTest < ActionDispatch::IntegrationTest
  include AuthProviderHelper

  setup do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
    FabManager::Application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'create and activate an OIDC provider' do
    # clean any existing auth provider config
    FileUtils.rm('config/auth_provider.yml', force: true)

    name = 'Sleede'
    post '/api/auth_providers',
         params: {
           auth_provider: keycloak_provider_params(name)
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the provider was correctly created
    db_provider = OpenIdConnectProvider.includes(:auth_provider).where('auth_providers.name': name).first&.auth_provider
    assert_not_nil db_provider

    provider = json_response(response.body)
    assert_equal name, provider[:name]
    assert_equal db_provider&.id, provider[:id]
    assert_equal 'pending', provider[:status]
    assert_equal 4, provider[:auth_provider_mappings_attributes].length

    # now let's activate this new provider
    Rake::Task['fablab:auth:switch_provider'].execute(Rake::TaskArguments.new([:provider], [name]))

    # Check it is correctly activated
    db_provider&.reload
    assert_equal 'active', db_provider&.status
    assert_equal AuthProvider.active.id, db_provider&.id

    # Check the configuration file
    assert File.exist?('config/auth_provider.yml')
    config = ProviderConfig.new
    assert_equal 'OpenIdConnectProvider', config.providable_type
    assert_equal name, config.name

    # clean test provider config
    FileUtils.rm('config/auth_provider.yml', force: true)
  end
end
