# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::SpacesTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all spaces' do
    get '/open_api/v1/spaces', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'get a space' do
    get '/open_api/v1/spaces/1', headers: open_api_headers(@token)
    assert_response :success
  end
end
