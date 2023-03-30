# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::ReservationsTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list reservations ' do
    get '/open_api/v1/reservations', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    assert_not_empty json_response(response.body)[:reservations]
  end

  test 'list all reservations with pagination' do
    get '/open_api/v1/reservations?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    reservations = json_response(response.body)
    assert reservations[:reservations].count <= 5
  end

  test 'list all reservations for a user' do
    get '/open_api/v1/reservations?user_id=3', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    reservations = json_response(response.body)
    assert_not_empty reservations[:reservations]
    assert_equal [3], reservations[:reservations].pluck(:user_id).uniq
  end

  test 'list all reservations for a user with pagination' do
    get '/open_api/v1/reservations?user_id=3&page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    reservations = json_response(response.body)
    assert reservations[:reservations].count <= 5
    assert_equal [3], reservations[:reservations].pluck(:user_id).uniq
  end

  test 'list all reservations with dates filtering' do
    get '/open_api/v1/reservations?after=2012-01-01T00:00:00+02:00&before=2012-12-31T23:59:59+02:00', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    reservations = json_response(response.body)
    assert reservations[:reservations].count.positive?
    assert(reservations[:reservations].all? do |line|
      date = Time.zone.parse(line[:created_at])
      date >= '2012-01-01'.to_date && date <= '2012-12-31'.to_date
    end)
  end

  test 'list all machine reservations for a user' do
    get '/open_api/v1/reservations?reservable_type=Machine&user_id=3', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    reservations = json_response(response.body)
    assert_not_empty reservations[:reservations]
    assert_equal [3], reservations[:reservations].pluck(:user_id).uniq
    assert_equal ['Machine'], reservations[:reservations].pluck(:reservable_type).uniq
  end

  test 'list all machine 2 reservations' do
    get '/open_api/v1/reservations?reservable_type=Machine&reservable_id=2', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    reservations = json_response(response.body)
    assert_not_empty reservations[:reservations]
    assert_equal [2], reservations[:reservations].pluck(:reservable_id).uniq
  end

  test 'list reservations filtered by availability' do
    get '/open_api/v1/reservations?availability_id=13', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    reservations = json_response(response.body)
    assert_not_empty reservations[:reservations]
    assert_equal [13], reservations[:reservations].pluck(:reserved_slots).flatten.pluck(:availability_id).uniq
  end
end
