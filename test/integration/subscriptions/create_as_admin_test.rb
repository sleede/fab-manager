# frozen_string_literal: true

require 'test_helper'

module Subscriptions; end

class Subscriptions::CreateAsAdminTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin successfully takes a subscription for a user' do
    user = User.find_by(username: 'jdupond')
    plan = Plan.find_by(group_id: user.group.id, type: 'Plan', base_name: 'Mensuel')

    VCR.use_cassette('subscriptions_admin_create_success') do
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

    # Check that the user has only one subscription
    assert_equal 1, user.subscriptions.count

    # Check that the user has the correct subscription
    assert_not_nil user.subscription, "user's subscription was not found"
    assert_not_nil user.subscription.plan, "user's subscribed plan was not found"
    assert_equal plan.id, user.subscription.plan_id, "user's plan does not match"

    # Check that the training credits were set correctly
    assert_empty user.training_credits, 'training credits were not reset'
    assert_equal user.subscription.plan.training_credit_nb, plan.training_credit_nb, 'trainings credits were not allocated'

    # Check that the user benefit from prices of his plan
    printer = Machine.find_by(slug: 'imprimante-3d')
    assert_equal 15,
                 (printer.prices.find_by(group_id: user.group_id, plan_id: user.subscription.plan_id).amount / 100.00),
                 'machine hourly price does not match'

    # Check notification was sent to the user
    notification = Notification.find_by(notification_type_id: NotificationType.find_by(name: 'notify_member_subscribed_plan'),
                                        attached_object_type: 'Subscription', attached_object_id: subscription.id)
    assert_not_nil notification, 'user notification was not created'
    assert_equal user.id, notification.receiver_id, 'wrong user notified'

    # Check generated invoice
    item = InvoiceItem.find_by(object_type: 'Subscription', object_id: subscription.id)
    invoice = item.invoice
    assert_invoice_pdf invoice
    assert_equal plan.amount, invoice.total, 'Invoice total price does not match the bought subscription'
  end

  test 'admin takes a subscription with a payment schedule' do
    user = User.find_by(username: 'jdupond')
    plan = Plan.find_by(group_id: user.group.id, type: 'Plan', base_name: 'Abonnement mensualisable')
    invoice_count = Invoice.count
    payment_schedule_count = PaymentSchedule.count
    payment_schedule_items_count = PaymentScheduleItem.count

    VCR.use_cassette('subscriptions_admin_create_with_payment_schedule') do
      post '/api/stripe/setup_subscription',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               customer_id: user.id,
               items: [
                 {
                   subscription: {
                     plan_id: plan.id
                   }
                 }
               ],
               payment_schedule: true,
               payment_method: 'cart'
             }
           }.to_json, headers: default_headers

      # Check response format & status
      assert_equal 201, response.status, response.body
      assert_match Mime[:json].to_s, response.content_type

      # Check the response
      res = json_response(response.body)
      assert_not_nil res[:id]
    end

    # Check generalities
    assert_equal invoice_count, Invoice.count, "an invoice was generated but it shouldn't"
    assert_equal payment_schedule_count + 1, PaymentSchedule.count, 'missing the payment schedule'
    assert_equal payment_schedule_items_count + 12, PaymentScheduleItem.count, 'missing some payment schedule items'

    # Check the correct plan was subscribed
    result = json_response(response.body)
    assert_equal PaymentSchedule.last.id, result[:id], 'payment schedule id does not match'
    subscription = PaymentSchedule.find(result[:id]).payment_schedule_objects.first.object
    assert_equal plan.id, subscription.plan_id, 'subscribed plan does not match'

    # Check that the user has the correct subscription
    assert_not_nil user.subscription, "user's subscription was not found"
    assert_not_nil user.subscription.plan, "user's subscribed plan was not found"
    assert_equal plan.id, user.subscription.plan_id, "user's plan does not match"
  end
end
