# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::PlanCategoriesTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all plan categories' do
    get '/open_api/v1/plan_categories', headers: open_api_headers(@token)
    assert_response :success
  end
end
