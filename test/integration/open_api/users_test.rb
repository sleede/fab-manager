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
  end

  test 'list all users filtering by email' do
    get '/open_api/v1/users?email=jean.dupond@gmail.com', headers: open_api_headers(@token)
    assert_response :success
  end
end
