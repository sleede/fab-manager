# frozen_string_literal: true

require 'test_helper'

module Subscriptions; end

class Subscriptions::RenewAsAdminTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin successfully renew a subscription before it has ended' do
    user = User.find_by(username: 'kdumas')
    plan = Plan.find_by(base_name: 'Mensuel tarif réduit')

    VCR.use_cassette('subscriptions_admin_renew_success') do
      post '/api/local_payment/confirm_payment',
           params: {
             customer_id: user.id,
             items: [
               {
                 subscription: {
                   plan_id: plan.id
                 }
               }
             ]
           }.to_json, headers: default_headers
    end

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct plan was subscribed
    result = json_response(response.body)
    assert_equal Invoice.last.id, result[:id], 'invoice id does not match'
    subscription = Invoice.find(result[:id]).invoice_items.first.object
    assert_equal plan.id, subscription.plan_id, 'subscribed plan does not match'

    # Check that the user has the correct subscription
    assert_not_nil user.subscription, "user's subscription was not found"
    assert_not_nil user.subscribed_plan, "user's subscribed plan was not found"
    assert_not_nil user.subscription.plan, "user's subscribed plan was not found"
    assert_equal plan.id, user.subscription.plan_id, "user's plan does not match"

    # Check the expiration date
    assert_equal (user.subscription.created_at + plan.interval_count.send(plan.interval)).to_i,
                 subscription.expiration_date.to_i,
                 'subscription expiration date does not match'

    # Check the subscription was correctly saved
    assert_equal 2, user.subscriptions.count

    # Check that the training credits were set correctly
    assert_empty user.training_credits, 'training credits were not reset'
    assert_equal user.subscription.plan.training_credit_nb, plan.training_credit_nb, 'trainings credits were not allocated'

    # Check that the user benefit from prices of his plan
    printer = Machine.find_by(slug: 'imprimante-3d')
    assert_equal 10,
                 (printer.prices.find_by(group_id: user.group_id, plan_id: user.subscription.plan_id).amount / 100),
                 'machine hourly price does not match'

    # Check notification was sent to the user
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_member_subscribed_plan'),
      attached_object_type: 'Subscription',
      attached_object_id: subscription[:id]
    )
    assert_not_nil notification, 'user notification was not created'
    assert_equal user.id, notification.receiver_id, 'wrong user notified'

    # Check generated invoice
    item = InvoiceItem.find_by(object_type: 'Subscription', object_id: subscription[:id])
    invoice = item.invoice
    assert_invoice_pdf invoice
    assert_equal plan.amount, invoice.total, 'Invoice total price does not match the bought subscription'
  end

  test 'admin successfully extends a subscription' do
    user = User.find_by(username: 'pdurand')
    subscription = user.subscription.clone
    new_date = subscription.expired_at + subscription.plan.interval_count.send(subscription.plan.interval)

    VCR.use_cassette('subscriptions_admin_extends_subscription') do
      post '/api/local_payment/confirm_payment',
           params: {
             customer_id: user.id,
             payment_method: 'check',
             payment_schedule: false,
             items: [
               {
                 subscription: {
                   start_at: subscription.expired_at.strftime('%Y-%m-%d %H:%M:%S.%9N %Z'),
                   plan_id: subscription.plan_id
                 }
               }
             ]
           }.to_json, headers: default_headers
    end

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    res_subscription = json_response(response.body)
    assert_equal 'Subscription', res_subscription[:main_object][:type]
    assert_equal subscription.plan.amount / 100.0, res_subscription[:items][0][:amount]

    # Check the subscription was correctly saved
    assert_equal 2, user.subscriptions.count

    # Check that the subscription is new
    assert_not_equal subscription.id, user.subscription.id, 'subscription id has not changed'
    assert_dates_equal new_date, user.subscription.expired_at, 'subscription end date does not match'

    # Check notification was sent to the user
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_member_subscribed_plan'),
      attached_object_type: 'Subscription',
      attached_object_id: subscription[:id]
    )
    assert_not_nil notification, 'user notification was not created'
    assert_equal user.id, notification.receiver_id, 'wrong user notified'
  end
end
