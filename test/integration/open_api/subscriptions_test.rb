# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::SubscriptionsTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all subscriptions' do
    get '/open_api/v1/subscriptions', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all subscriptions with pagination' do
    get '/open_api/v1/subscriptions?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all subscriptions for a user' do
    get '/open_api/v1/subscriptions?user_id=3', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all subscriptions for a user with pagination' do
    get '/open_api/v1/subscriptions?user_id=3&page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all subscriptions for a plan with pagination' do
    get '/open_api/v1/subscriptions?plan_id=1&page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end
end
