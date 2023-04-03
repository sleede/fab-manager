# frozen_string_literal: true

require 'test_helper'

class StatusesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a status' do
    post '/api/statuses',
         params: {
           name: 'Open'
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct status was created
    res = json_response(response.body)
    status = Status.where(id: res[:id]).first
    assert_not_nil status, 'status was not created in database'

    assert_equal 'Open', res[:name]
  end

  test 'update a status' do
    patch '/api/statuses/1',
          params: {
            name: 'Done'
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the status was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 'Done', res[:name]
  end

  test 'list all statuses' do
    get '/api/statuses'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    statuses = json_response(response.body)
    assert_equal Status.count, statuses.count
  end

  test 'delete a status' do
    status = Status.create!(name: 'Gone too soon')
    delete "/api/statuses/#{status.id}"
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      status.reload
    end
  end
end
