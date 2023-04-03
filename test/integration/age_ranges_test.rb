# frozen_string_literal: true

require 'test_helper'

class AgeRangesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create an age range' do
    post '/api/age_ranges',
         params: {
           name: '8 - 10 ans'
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct age range was created
    res = json_response(response.body)
    range = AgeRange.where(id: res[:id]).first
    assert_not_nil range, 'range was not created in database'

    assert_equal '8 - 10 ans', res[:name]
  end

  test 'update an age range' do
    patch '/api/age_ranges/1',
          params: {
            name: "Jusqu'à 17 ans"
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the age range was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal "Jusqu'à 17 ans", res[:name]
  end

  test 'list all age ranges' do
    get '/api/age_ranges'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    ranges = json_response(response.body)
    assert_equal AgeRange.count, ranges.count
  end

  test 'delete an age range' do
    delete '/api/age_ranges/1'
    assert_response :success
    assert_empty response.body
  end
end
