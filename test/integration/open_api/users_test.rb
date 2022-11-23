# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::UsersTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all users' do
    get '/open_api/v1/users', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all users with pagination' do
    get '/open_api/v1/users?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all users filtering by IDs' do
    get '/open_api/v1/users?user_id=[3,4,5]', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    users = json_response(response.body)
    assert users[:users].count.positive?
    assert(users[:users].all? { |user| [3, 4, 5].include?(user[:id]) })
  end

  test 'list a user filtering by ID' do
    get '/open_api/v1/users?user_id=2', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    users = json_response(response.body)
    assert_equal 1, users[:users].count
    assert_equal 2, users[:users].first[:id]
  end

  test 'list all users filtering by email' do
    get '/open_api/v1/users?email=jean.dupond@gmail.com', headers: open_api_headers(@token)
    assert_response :success
  end
end
