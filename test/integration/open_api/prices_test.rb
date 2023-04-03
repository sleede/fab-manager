# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::PricesTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all prices' do
    get '/open_api/v1/prices', headers: open_api_headers(@token)
    assert_response :success

    assert_equal Price.count, json_response(response.body)[:prices].length
  end

  test 'list all prices with pagination' do
    get '/open_api/v1/prices?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success

    assert_equal 5, json_response(response.body)[:prices].length
  end

  test 'list all prices for a specific machine' do
    get '/open_api/v1/prices?priceable_type=Machine&priceable_id=1', headers: open_api_headers(@token)
    assert_response :success

    assert_equal [1], json_response(response.body)[:prices].pluck(:priceable_id).uniq
  end

  test 'list all prices for some groups' do
    get '/open_api/v1/prices?group_id=[1,2]', headers: open_api_headers(@token)
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    prices = json_response(response.body)
    assert_equal [1, 2], prices[:prices].pluck(:group_id).uniq.sort
  end
end
