# frozen_string_literal: true

require 'test_helper'

class NotificationPreferencesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'Index lists all notification preferences for a user' do
    get '/api/notification_preferences'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok and don't include other users' notification preferences
    notification_preferences = json_response(response.body)
    assert_not_equal notification_preferences.count, 0
    assert_equal NotificationPreference.where(user: @admin).count, notification_preferences.count
  end

  test 'update a notification preference' do
    patch '/api/notification_preferences/1',
          params: {
            notification_preference: {
              id: 1,
              user_id: 1,
              notification_type: 'notify_admin_when_project_published',
              in_system: false,
              email: false
            }
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the status was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 'notify_admin_when_project_published', res[:notification_type]
    assert_equal false, res[:in_system]
    assert_equal false, res[:email]
  end

  test 'bulk update notification preference' do
    patch '/api/notification_preferences/bulk_update',
          params: {
            notification_preferences: [
              {
                id: 1,
                user_id: 1,
                notification_type: 'notify_admin_when_project_published',
                in_system: false,
                email: false
              },
              {
                id: 2,
                user_id: 1,
                notification_type: 'notify_project_collaborator_to_valid',
                in_system: false,
                email: false
              }
            ]
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 204, response.status, response.body

    # Check records
    first_notification_preference = NotificationPreference.find(1)
    assert_not_nil first_notification_preference, 'notification preference was not found in database'
    assert_equal first_notification_preference.email, false
    assert_equal first_notification_preference.in_system, false

    second_notification_preference = NotificationPreference.find(2)
    assert_not_nil second_notification_preference, 'notification preference was not found in database'
    assert_equal second_notification_preference.email, false
    assert_equal second_notification_preference.in_system, false
  end
end
