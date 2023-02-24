# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::SubscriptionsTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list subscriptions' do
    get '/open_api/v1/subscriptions', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    assert_not_empty json_response(response.body)[:subscriptions]
  end

  test 'list subscriptions with pagination' do
    get '/open_api/v1/subscriptions?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    subscriptions = json_response(response.body)
    assert subscriptions[:subscriptions].count <= 5
  end

  test 'list all subscriptions for a user' do
    get '/open_api/v1/subscriptions?user_id=3', headers: open_api_headers(@token)
    assert_response :success

    subscriptions = json_response(response.body)
    assert_not_empty subscriptions[:subscriptions]
    assert_equal [3], subscriptions[:subscriptions].pluck(:user_id).uniq
  end

  test 'list all subscriptions for a user with pagination' do
    get '/open_api/v1/subscriptions?user_id=3&page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success

    subscriptions = json_response(response.body)
    assert_not_empty subscriptions[:subscriptions]
    assert_equal [3], subscriptions[:subscriptions].pluck(:user_id).uniq
    assert subscriptions[:subscriptions].count <= 5
  end

  test 'list all subscriptions for a plan with pagination' do
    get '/open_api/v1/subscriptions?plan_id=1&page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success

    subscriptions = json_response(response.body)
    assert_not_empty subscriptions[:subscriptions]
    assert_equal [1], subscriptions[:subscriptions].pluck(:plan_id).uniq
    assert subscriptions[:subscriptions].count <= 5
  end
end
