# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::BookableMachinesTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all bookable machines without user_id' do
    get '/open_api/v1/bookable_machines', headers: open_api_headers(@token)
    assert_response :internal_server_error
  end

  test 'list all bookable machines' do
    get '/open_api/v1/bookable_machines?user_id=3', headers: open_api_headers(@token)
    assert_response :success
  end
end
