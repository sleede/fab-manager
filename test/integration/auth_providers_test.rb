# frozen_string_literal: true

require 'test_helper'

class AuthProvidersTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end


  test 'create an auth external provider and activate it' do
    name = 'GitHub'
    post '/api/auth_providers',
         params: {
           auth_provider: {
             name: name,
             providable_type: 'OAuth2Provider',
             providable_attributes: {
               authorization_endpoint: 'authorize',
               token_endpoint: 'access_token',
               base_url: 'https://github.com/login/oauth/',
               profile_url: 'https://github.com/settings/profile',
               client_id: ENV.fetch('OAUTH_CLIENT_ID') { 'github-oauth-app-id' },
               client_secret: ENV.fetch('OAUTH_CLIENT_SECRET') { 'github-oauth-app-secret' },
               o_auth2_mappings_attributes: [
                 {
                   api_data_type: 'json',
                   api_endpoint: 'https://api.github.com/user',
                   api_field: 'id',
                   local_field: 'uid',
                   local_model: 'user'
                 },
                 {
                   api_data_type: 'json',
                   api_endpoint: 'https://api.github.com/user',
                   api_field: 'html_url',
                   local_field: 'github',
                   local_model: 'profile'
                 }
               ]
             }
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime[:json], response.content_type

    # Check the provider was correctly created
    db_provider = OAuth2Provider.includes(:auth_provider).where('auth_providers.name': name).first.auth_provider
    assert_not_nil db_provider

    provider = json_response(response.body)
    assert_equal name, provider[:name]
    assert_equal db_provider.id, provider[:id]
    assert_equal 'pending', provider[:status]
    assert_equal 2, provider[:providable_attributes][:o_auth2_mappings_attributes].length

    # now let's activate this new provider
    Fablab::Application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task['fablab:auth:switch_provider'].invoke(name)

    db_provider.reload
    assert_equal 'active', db_provider.status
    assert_equal AuthProvider.active.id, db_provider.id
    User.all.each do |u|
      assert_not_nil u.auth_token
    end
  end
end
