# frozen_string_literal: true

require 'test_helper'

class NotificationTypesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'Index lists all notification types' do
    get '/api/notification_types'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    notification_types = json_response(response.body)
    assert_not_equal notification_types.count, 0
    assert_equal NotificationType.count, notification_types.count
  end

  test 'Index with params[:is_configurable] lists only configurable notification types' do
    get '/api/notification_types?is_configurable=true'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    notification_types = json_response(response.body)
    assert_not_equal notification_types.count, 0
    assert_equal NotificationType.where(is_configurable: true).count, notification_types.count
  end
end
