# frozen_string_literal: true

require 'test_helper'
require 'helpers/auth_provider_helper'

class AuthProvidersTest < ActionDispatch::IntegrationTest
  include AuthProviderHelper

  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
    FabManager::Application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'create an auth external provider and activate it' do
    # clean any existing auth provider config
    FileUtils.rm('config/auth_provider.yml', force: true)

    name = 'GitHub'
    post '/api/auth_providers',
         params: {
           auth_provider: github_provider_params(name)
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the provider was correctly created
    db_provider = OAuth2Provider.includes(:auth_provider).where('auth_providers.name': name).first&.auth_provider
    assert_not_nil db_provider

    provider = json_response(response.body)
    assert_equal name, provider[:name]
    assert_equal db_provider&.id, provider[:id]
    assert_equal 'pending', provider[:status]
    assert_equal 2, provider[:auth_provider_mappings_attributes].length

    # now let's activate this new provider
    Rake::Task['fablab:auth:switch_provider'].execute(Rake::TaskArguments.new([:provider], [name]))

    db_provider&.reload
    assert_equal 'active', db_provider&.status
    assert_equal AuthProvider.active.id, db_provider&.id
    User.find_each do |u|
      assert_not_nil u.auth_token
    end

    # Check the configuration file
    assert File.exist?('config/auth_provider.yml')
    config = ProviderConfig.new
    assert_equal 'OAuth2Provider', config.providable_type
    assert_equal name, config.name

    # clean test provider config
    FileUtils.rm('config/auth_provider.yml', force: true)
  end

  test 'update an authentication provider' do
    provider = AuthProvider.create!(github_provider_params('GitHub'))
    patch "/api/auth_providers/#{provider.id}",
          params: {
            auth_provider: {
              providable_type: 'OAuth2Provider',
              auth_provider_mappings_attributes: [
                { api_data_type: 'json', api_endpoint: 'https://api.github.com/user',
                  api_field: 'avatar_url', local_field: 'avatar', local_model: 'profile' }
              ]
            }
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    provider.reload

    # Check the provider was updated
    res = json_response(response.body)
    assert_equal provider.id, res[:id]
    assert_equal 3, provider.auth_provider_mappings.count
    assert_not_nil provider.auth_provider_mappings.find_by(api_field: 'avatar_url')
  end

  test 'build an oauth2 strategy name' do
    get '/api/auth_providers/strategy_name?providable_type=OAuth2Provider&name=Sleede'

    assert_response :success
    assert_equal 'oauth2-sleede', response.body
  end

  test 'build an openid strategy name' do
    get '/api/auth_providers/strategy_name?providable_type=OpenIdConnectProvider&name=Sleede'

    assert_response :success
    assert_equal 'openidconnect-sleede', response.body
  end

  test 'list all authentication providers' do
    get '/api/auth_providers'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the answer
    res = json_response(response.body)
    assert_equal AuthProvider.count, res.length
  end

  test 'show an authentication provider' do
    provider = AuthProvider.first
    get "/api/auth_providers/#{provider.id}"

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the provider
    res = json_response(response.body)
    assert_equal provider.id, res[:id]
    assert_equal provider.providable_type, res[:providable_type]
  end

  test 'show fields available for mapping' do
    get '/api/auth_providers/mapping_fields'

    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the returned fields
    res = json_response(response.body)
    assert_not_empty res[:user]
    assert_not_empty res[:profile]
    assert_not res[:user].map(&:first).include?('encrypted_password')
    assert(res[:user].map(&:last).all? { |type| %w[string boolean integer datetime].include?(type) })
  end

  test 'get the current active provider' do
    get '/api/auth_providers/active'

    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the returned fields
    res = json_response(response.body)
    assert_equal AuthProvider.active.id, res[:id]
    assert_nil res[:previous_provider]
  end

  test 'send auth migration token' do
    # create an enable an oauth2 provider
    name = 'TokenTest'
    AuthProvider.create!(github_provider_params(name))
    Rake::Task['fablab:auth:switch_provider'].execute(Rake::TaskArguments.new([:provider], [name]))

    # send the migration token
    user = User.find(10)
    post '/api/auth_providers/send_code',
         params: {
           email: user.email
         }.to_json,
         headers: default_headers

    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # check resulting notification
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_user_auth_migration'),
      attached_object_type: 'User',
      attached_object_id: user.id
    )
    assert_not_nil notification, 'user notification was not created'
  end
end
