# frozen_string_literal: true

require 'test_helper'

module Subscriptions; end

class Subscriptions::RenewAsUserTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.find_by(username: 'atiermoulin')
    login_as(@user, scope: :user)
  end

  test 'user successfully renew a subscription after it has ended' do
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan', base_name: 'Mensuel')

    VCR.use_cassette('subscriptions_user_renew_success', erb: true) do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               items: [
                 {
                   subscription: {
                     plan_id: plan.id
                   }
                 }
               ]
             }
           }.to_json, headers: default_headers
    end

    # Check response format & status
    assert_equal 201, response.status, "API does not return the expected status. #{response.body}"
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct plan was subscribed
    result = json_response(response.body)
    assert_equal Invoice.last.id, result[:id], 'invoice id does not match'
    subscription = Invoice.find(result[:id]).invoice_items.first.object
    assert_equal plan.id, subscription.plan_id, 'subscribed plan does not match'

    # Check the subscription was correctly saved
    assert_equal 2, @user.subscriptions.count

    # Check that the user has the correct subscription
    assert_not_nil @user.subscription, "user's subscription was not found"

    # Check the expiration date
    assert @user.subscription.expired_at > Time.current,
           "user's subscription expiration was not updated ... VCR cassettes may be outdated, please check the gitlab wiki"
    assert_equal @user.subscription.expired_at.iso8601,
                 (@user.subscription.created_at + plan.duration).iso8601,
                 'subscription expiration date does not match'

    assert_in_delta 5,
                    (Time.current.to_i - @user.subscription.updated_at.to_i),
                    10,
                    "user's subscription was not updated recently"

    # Check that the credits were reset correctly
    assert_empty @user.users_credits, 'credits were not reset'

    # Check notifications were sent for every admins
    notifications = Notification.where(
      notification_type_id: NotificationType.find_by(name: 'notify_admin_subscribed_plan'),
      attached_object_type: 'Subscription',
      attached_object_id: subscription[:id]
    )
    assert_not_empty notifications, 'no notifications were created'
    notified_users_ids = notifications.map(&:receiver_id)
    User.admins.each do |adm|
      assert_includes notified_users_ids, adm.id, "Admin #{adm.id} was not notified"
    end

    # Check generated invoice
    item = InvoiceItem.find_by(object_type: 'Subscription', object_id: subscription[:id])
    invoice = item.invoice
    assert_invoice_pdf invoice
    assert_equal plan.amount, invoice.total, 'Invoice total price does not match the bought subscription'
  end

  test 'user fails to renew a subscription' do
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan', base_name: 'Mensuel')

    previous_expiration = @user.subscription.expired_at.to_i

    VCR.use_cassette('subscriptions_user_renew_failed') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method(error: :card_declined),
             cart_items: {
               items: [
                 {
                   subscription: {
                     plan_id: plan.id
                   }
                 }
               ]
             }
           }.to_json, headers: default_headers
    end

    # Check response format & status
    assert_equal 200, response.status, "API does not return the expected status. #{response.body}"
    assert_match Mime[:json].to_s, response.content_type

    # Check the error was handled
    assert_match(/Your card was declined/, response.body)

    # Check that the user's subscription has not changed
    assert_equal previous_expiration, @user.subscription.expired_at.to_i, "user's subscription has changed"

    # Check the subscription was not saved
    assert_equal 1, @user.subscriptions.count
  end
end
