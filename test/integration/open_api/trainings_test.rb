# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::TrainingsTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all trainings' do
    get '/open_api/v1/trainings', headers: open_api_headers(@token)
    assert_response :success
  end
end
