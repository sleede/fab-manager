# frozen_string_literal: true

require 'test_helper'

module Subscriptions; end

class Subscriptions::CancelTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin cancel a subscription for a user' do
    subscription = Subscription.find(1)

    patch "/api/subscriptions/#{subscription.id}/cancel", headers: default_headers

    # Check response format & status
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    # Check the subscription was canceled
    subscription.reload
    assert subscription.expiration_date < Time.current
    assert subscription.canceled_at < Time.current
    assert subscription.expired_at < Time.current
    assert subscription.expired?
    assert_nil subscription.user.subscribed_plan

    # Notifications
    notifications = Notification.where(notification_type: NotificationType.find_by(name: 'notify_admin_subscription_canceled'),
                                       attached_object: subscription)
    notified_users_ids = notifications.map(&:receiver_id)
    assert_not_empty notifications
    assert(User.admins.map(&:id).all? { |admin| notified_users_ids.include?(admin) })

    user_notification = Notification.where(notification_type: NotificationType.find_by(name: 'notify_member_subscription_canceled'),
                                           attached_object: subscription)
    assert_equal 1, user_notification.count
  end

  test 'admin offer free days then cancel the subscription' do
    subscription = Subscription.find(1)
    new_date = 1.month.from_now.utc

    post '/api/local_payment/confirm_payment',
         params: {
           customer_id: subscription.user.id,
           items: [{ free_extension: { end_at: new_date.strftime('%Y-%m-%d %H:%M:%S.%9N %Z') } }]
         }.to_json, headers: default_headers

    assert_response :success

    patch "/api/subscriptions/#{subscription.id}/cancel", headers: default_headers

    # Check response format & status
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    # Check the subscription was canceled
    subscription.reload
    assert subscription.expiration_date < Time.current
    assert subscription.canceled_at < Time.current
    assert subscription.expired_at < Time.current
    assert subscription.expired?
    assert_nil subscription.user.subscribed_plan
  end
end
