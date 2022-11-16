# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::AccountingTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all accounting lines' do
    get '/open_api/v1/accounting', headers: open_api_headers(@token)
    assert_response :success
  end
end
