# frozen_string_literal: true

require 'test_helper'

module Subscriptions; end

class Subscriptions::FreeExtensionTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin successfully offer free days' do
    user = User.find_by(username: 'pdurand')
    subscription = user.subscription.clone
    new_date = (1.month.from_now - 4.days).utc
    offer_days_count = OfferDay.count

    VCR.use_cassette('subscriptions_admin_offer_free_days') do
      post '/api/local_payment/confirm_payment',
           params: {
             customer_id: user.id,
             items: [
               {
                 free_extension: {
                   end_at: new_date.strftime('%Y-%m-%d %H:%M:%S.%9N %Z')
                 }
               }
             ]
           }.to_json, headers: default_headers
    end

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check that the subscribed plan was not altered
    res = json_response(response.body)
    assert_equal 'OfferDay', res[:main_object][:type]
    assert_equal 0, res[:items][0][:amount]

    assert_equal subscription.id, user.subscription.id, 'subscription id has changed'
    assert_equal subscription.plan_id, user.subscription.plan_id, 'subscribed plan does not match'
    assert_dates_equal new_date, user.subscription.expired_at, 'subscription end date was not updated'

    # Check the subscription was correctly saved
    assert_equal 1, user.subscriptions.count
    assert_equal offer_days_count + 1, OfferDay.count

    # Check notification was sent to the user
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_member_subscription_extended'),
      attached_object_type: 'Subscription',
      attached_object_id: subscription[:id]
    )
    assert_not_nil notification, 'user notification was not created'
    assert_not_nil notification.get_meta_data(:free_days),
                   "notification didn't says to the user that her extent was for free"
    assert_equal user.id, notification.receiver_id, 'wrong user notified'
  end

  test 'admin cannot offer negative free days' do
    user = User.find_by(username: 'pdurand')
    new_date = (user.subscription.expiration_date - 4.days).utc

    post '/api/local_payment/confirm_payment',
         params: {
           customer_id: user.id,
           items: [
             {
               free_extension: {
                 end_at: new_date.strftime('%Y-%m-%d %H:%M:%S.%9N %Z')
               }
             }
           ]
         }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 422, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check that the subscribed plan was not altered
    res = json_response(response.body)
    assert_equal I18n.t('cart_items.must_be_after_expiration'), res
  end
end
