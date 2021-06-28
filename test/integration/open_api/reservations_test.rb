# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::ReservationsTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all reservations' do
    get '/open_api/v1/reservations', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all reservations with pagination' do
    get '/open_api/v1/reservations?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all reservations for a user' do
    get '/open_api/v1/reservations?user_id=3', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all reservations for a user with pagination' do
    get '/open_api/v1/reservations?user_id=3&page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all machine reservations for a user' do
    get '/open_api/v1/reservations?reservable_type=Machine&user_id=3', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all machine 4 reservations' do
    get '/open_api/v1/reservations?reservable_type=Machine&reservable_id=4', headers: open_api_headers(@token)
    assert_response :success
  end
end
