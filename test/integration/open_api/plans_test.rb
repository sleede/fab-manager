# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::PlansTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all plans' do
    get '/open_api/v1/plans', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'get a plan' do
    get '/open_api/v1/plans/1', headers: open_api_headers(@token)
    assert_response :success
  end
end
