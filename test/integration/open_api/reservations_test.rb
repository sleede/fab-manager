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
    assert_equal Mime[:json], response.content_type

    assert_equal Reservation.count, json_response(response.body)[:reservations].length
  end

  test 'list all reservations with pagination' do
    get '/open_api/v1/reservations?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    reservations = json_response(response.body)
    assert reservations[:reservations].count <= 5
  end

  test 'list all reservations for a user' do
    get '/open_api/v1/reservations?user_id=3', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    reservations = json_response(response.body)
    assert_not_empty reservations[:reservations]
    assert_equal [3], reservations[:reservations].pluck(:user_id).uniq
  end

  test 'list all reservations for a user with pagination' do
    get '/open_api/v1/reservations?user_id=3&page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    reservations = json_response(response.body)
    assert reservations[:reservations].count <= 5
    assert_equal [3], reservations[:reservations].pluck(:user_id).uniq
  end

  test 'list all machine reservations for a user' do
    get '/open_api/v1/reservations?reservable_type=Machine&user_id=3', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    reservations = json_response(response.body)
    assert_not_empty reservations[:reservations]
    assert_equal [3], reservations[:reservations].pluck(:user_id).uniq
    assert_equal ['Machine'], reservations[:reservations].pluck(:reservable_type).uniq
  end

  test 'list all machine 2 reservations' do
    get '/open_api/v1/reservations?reservable_type=Machine&reservable_id=2', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    reservations = json_response(response.body)
    assert_not_empty reservations[:reservations]
    assert_equal [2], reservations[:reservations].pluck(:reservable_id).uniq
  end
end
