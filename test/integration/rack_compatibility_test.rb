# frozen_string_literal: true

require 'test_helper'

# Check the real Rails/Redis/Devise boundary with CSRF validation enabled.
class RackCompatibilityTest < ActionDispatch::IntegrationTest
  setup do
    @previous_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    @member = users(:user2)
    @password = 'Local-review-password-123!'
    @member.update!(password: @password, password_confirmation: @password)
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @previous_forgery_protection
    Warden.test_reset!
  end

  test 'rejects login with an invalid CSRF token without authenticating the member' do
    get '/api/machines'
    assert_response :success

    assert_not_empty cookies['XSRF-TOKEN']
    assert_raises(ActionController::InvalidAuthenticityToken) do
      post '/users/sign_in', params: { user: { email: @member.email, password: @password } },
                             headers: { 'Accept' => 'application/json', 'X-XSRF-TOKEN' => 'invalid-local-token' }
    end
    get '/api/members/current'
    assert_response :unauthorized
  end

  test 'preserves a real login session and clears it on logout with valid CSRF tokens' do
    get '/api/machines'
    assert_response :success
    token = cookies['XSRF-TOKEN']

    assert_not_empty token
    post '/users/sign_in', params: { user: { email: @member.email, password: @password } },
                           headers: { 'Accept' => 'application/json', 'X-XSRF-TOKEN' => token }

    assert_response :success
    assert cookies['_Fab-manager_session']
    get '/api/members/current'
    assert_response :success
    assert_equal @member.id, response.parsed_body.fetch('id')

    delete '/users/sign_out', headers: { 'Accept' => 'application/json', 'X-XSRF-TOKEN' => cookies['XSRF-TOKEN'] }

    assert_response :success
    get '/api/members/current'
    assert_response :unauthorized
  end

  test 'JSON login authenticates only with the Devise user envelope and a valid CSRF token' do
    get '/api/machines'
    headers = { 'Accept' => 'application/json', 'X-XSRF-TOKEN' => cookies['XSRF-TOKEN'] }

    post '/users/sign_in', params: { email: @member.email, password: @password }, as: :json, headers: headers
    assert_response :unauthorized
    get '/api/members/current'
    assert_response :unauthorized

    post '/users/sign_in', params: { user: { email: @member.email, password: @password } }, as: :json,
                           headers: headers.merge('X-XSRF-TOKEN' => cookies['XSRF-TOKEN'])
    assert_response :success
    get '/api/members/current'
    assert_response :success
    assert_equal @member.id, response.parsed_body.fetch('id')
  end

  test 'allows the authenticated admin to use the mounted Sidekiq application' do
    login_as(users(:user1), scope: :user)
    get '/admin/sidekiq'

    assert_response :success
    assert_includes response.body, 'Sidekiq'
  end
end
