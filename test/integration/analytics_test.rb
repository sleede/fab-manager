# frozen_string_literal: true

require 'test_helper'

class AnalyticsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    @jdupond = User.find_by(username: 'jdupond')
  end

  test 'fetch analytics data' do
    login_as(@admin, scope: :user)

    get '/api/analytics/data'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the resulting data was created
    res = json_response(response.body)
    assert_not_nil res[:version]
    assert_not_nil res[:members]
    assert_not_nil res[:admins]
    assert_not_nil res[:managers]
    assert_not_nil res[:availabilities]
    assert_not_nil res[:reservations]
    assert_not_nil res[:orders]
  end

  test 'non-admin cannot fetch analytics data' do
    login_as(@jdupond, scope: :user)
    get '/api/analytics/data'

    assert_response :forbidden
  end
end
