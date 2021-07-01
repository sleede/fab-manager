# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::UsersTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all user trainings' do
    get '/open_api/v1/user_trainings', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all user trainings with pagination' do
    get '/open_api/v1/user_trainings?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all user trainings filtering by training' do
    get '/open_api/v1/user_trainings?training_id=[2,3,4]', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all user trainings filtering by user' do
    get '/open_api/v1/user_trainings?user_id=[4,5]', headers: open_api_headers(@token)
    assert_response :success
  end
end
