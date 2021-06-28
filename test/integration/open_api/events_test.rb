# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::EventsTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all events' do
    get '/open_api/v1/events', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all events with pagination' do
    get '/open_api/v1/events?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list events for a given IDs' do
    get '/open_api/v1/events?id=[3,4]', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all upcoming events' do
    get '/open_api/v1/events?upcoming=true', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all upcoming events with pagination' do
    get '/open_api/v1/events?upcoming=true&page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end
end
