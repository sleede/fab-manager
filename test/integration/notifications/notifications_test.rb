# frozen_string_literal: true

require 'test_helper'

class NotificationsTest < ActionDispatch::IntegrationTest
  test 'Index lists all notifications if user has no notifications preferences' do
    @member = User.find(4)
    login_as(@member, scope: :user)

    get '/api/notifications'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    # ! Only works if notifications fixtures for this user are < NOTIFICATIONS_PER_PAGE (See NotificationsController#index)
    notifications_total = json_response(response.body)[:totals][:total]

    assert_not_equal notifications.count, 0
    assert_equal Notification.where(receiver_id: @member.id).count, notifications_total
  end

  test 'Index filters notifications if user has preferences for in_system notifications set to false' do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)

    get '/api/notifications'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    notifications_total = json_response(response.body)[:totals][:total]
    assert_not_equal notifications.count, 0

    assert_equal NotificationPreference.where(user_id: @admin.id, in_system: false).count, 1
    assert_equal (Notification.where(receiver_id: @admin.id).count - 1), notifications_total
  end

  test 'Last unread returns last 3 unread notifications' do
    @member = User.find(4)
    login_as(@member, scope: :user)

    transaction1 = WalletService.new(user: @member, wallet: @member.wallet).credit(1)
    transaction2 = WalletService.new(user: @member, wallet: @member.wallet).credit(2)
    transaction3 = WalletService.new(user: @member, wallet: @member.wallet).credit(4)

    get '/api/notifications/last_unread'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    # Beware that the order of last unread notifications is descending,
    # Since the last created will be the first to appear.
    last_notifications = json_response(response.body)[:notifications]
    assert_equal last_notifications[0][:attached_object][:id], transaction3.id
    assert_equal last_notifications[1][:attached_object][:id], transaction2.id
    assert_equal last_notifications[2][:attached_object][:id], transaction1.id
  end

  test 'update marks a notification as read' do
    @member = User.find(4)
    login_as(@member, scope: :user)

    transaction = WalletService.new(user: @member, wallet: @member.wallet).credit(1)

    notification = Notification.where(receiver_id: @member.id).last
    assert_equal notification.attached_object_id, transaction.id
    assert_equal notification.is_read, false

    patch "/api/notifications/#{notification.id}"

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    updated_notification = json_response(response.body)

    assert_equal updated_notification[:attached_object][:id], transaction.id
    assert_equal updated_notification[:is_read], true
  end

  test 'update_all marks all notification as read' do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)

    patch '/api/notifications'

    # Check response format & status
    assert_equal 204, response.status, response.body

    notifications = Notification.where(receiver_id: @admin.id)

    notifications.each do |notification|
      assert_equal true, notification.is_read
    end
  end
end
