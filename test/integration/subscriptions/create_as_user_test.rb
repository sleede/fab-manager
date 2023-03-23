# frozen_string_literal: true

require 'test_helper'

module Subscriptions; end

class Subscriptions::CreateAsUserTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.find_by(username: 'jdupond')
    login_as(@user, scope: :user)
  end

  test 'user successfully takes a subscription' do
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan', base_name: 'Mensuel')

    VCR.use_cassette('subscriptions_user_create_success') do
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
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct plan was subscribed
    result = json_response(response.body)
    assert_equal Invoice.last.id, result[:id], 'invoice id does not match'
    subscription = Invoice.find(result[:id]).invoice_items.first.object
    assert_equal plan.id, subscription.plan_id, 'subscribed plan does not match'

    # Check that the user has only one subscription
    assert_equal 1, @user.subscriptions.count

    # Check that the user has the correct subscription
    assert_not_nil @user.subscription, "user's subscription was not found"
    assert_not_nil @user.subscription.plan, "user's subscribed plan was not found"
    assert_equal plan.id, @user.subscription.plan_id, "user's plan does not match"

    # Check that the training credits were set correctly
    assert_empty @user.training_credits, 'training credits were not reset'
    assert_equal @user.subscription.plan.training_credit_nb, plan.training_credit_nb, 'trainings credits were not allocated'

    # Check that the user benefit from prices of his plan
    printer = Machine.find_by(slug: 'imprimante-3d')
    assert_equal 15,
                 (printer.prices.find_by(group_id: @user.group_id, plan_id: @user.subscription.plan_id).amount / 100.00),
                 'machine hourly price does not match'

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

  test 'user fails to take a subscription' do
    # get plan for wrong group
    plan = Plan.where.not(group_id: @user.group.id).first

    VCR.use_cassette('subscriptions_user_create_failed') do
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
    assert_equal 422, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the error was handled
    assert_match(/plan is reserved for members of group/, response.body)

    # Check that the user has no subscription
    assert_nil @user.subscription, "user's subscription was found"
  end

  test 'user successfully takes a subscription with wallet' do
    @vlonchamp = User.find_by(username: 'vlonchamp')
    login_as(@vlonchamp, scope: :user)
    plan = Plan.find_by(group_id: @vlonchamp.group.id, type: 'Plan', base_name: 'Mensuel tarif réduit')

    VCR.use_cassette('subscriptions_user_create_success_with_wallet') do
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

    @vlonchamp.wallet.reload

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct plan was subscribed
    result = json_response(response.body)
    assert_equal Invoice.last.id, result[:id], 'invoice id does not match'
    subscription = Invoice.find(result[:id]).invoice_items.first.object
    assert_equal plan.id, subscription.plan_id, 'subscribed plan does not match'

    # Check that the user has the correct subscription
    assert_not_nil @vlonchamp.subscription, "user's subscription was not found"
    assert_not_nil @vlonchamp.subscription.plan, "user's subscribed plan was not found"
    assert_equal plan.id, @vlonchamp.subscription.plan_id, "user's plan does not match"

    # Check that the training credits were set correctly
    assert_empty @vlonchamp.training_credits, 'training credits were not reset'
    assert_equal @vlonchamp.subscription.plan.training_credit_nb,
                 plan.training_credit_nb,
                 'trainings credits were not allocated'

    # Check that the user benefit from prices of his plan
    printer = Machine.find_by(slug: 'imprimante-3d')
    assert_equal 10,
                 (printer.prices.find_by(
                   group_id: @vlonchamp.group_id,
                   plan_id: @vlonchamp.subscription.plan_id
                 ).amount / 100.00
                 ),
                 'machine hourly price does not match'

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

    # wallet
    assert_equal 0, @vlonchamp.wallet.amount
    assert_equal 2, @vlonchamp.wallet.wallet_transactions.count
    transaction = @vlonchamp.wallet.wallet_transactions.last
    assert_equal 'debit', transaction.transaction_type
    assert_equal 10, transaction.amount
    assert_equal invoice.wallet_amount / 100.0, transaction.amount
    assert_equal invoice.wallet_transaction_id, transaction.id
  end

  test 'user takes a subscription but does not confirm 3DS' do
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan', base_name: 'Abonnement mensualisable')
    payment_schedule_count = PaymentSchedule.count
    payment_schedule_items_count = PaymentScheduleItem.count

    VCR.use_cassette('subscriptions_user_create_without_3ds_confirmation') do
      post '/api/stripe/setup_subscription',
           params: {
             payment_method_id: stripe_payment_method(error: :require_3ds),
             cart_items: {
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
      assert_equal 200, response.status, response.body
      assert_match Mime[:json].to_s, response.content_type

      # Check the response
      res = json_response(response.body)
      assert res[:requires_action]
      assert_not_nil res[:payment_intent_client_secret]
      assert_not_nil res[:subscription_id]
      assert_equal 'subscription', res[:type]

      # try to confirm the subscription
      post '/api/stripe/confirm_subscription',
           params: {
             subscription_id: res[:subscription_id],
             cart_items: {
               payment_schedule: true,
               payment_method: 'card',
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

    # Check generalities
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    res = json_response(response.body)
    assert res[:requires_action]
    assert_not_nil res[:payment_intent_client_secret]
    assert_not_nil res[:subscription_id]
    assert_equal 'subscription', res[:type]

    assert_equal payment_schedule_count, PaymentSchedule.count, 'the payment schedule was created anyway'
    assert_equal payment_schedule_items_count, PaymentScheduleItem.count, 'some payment schedule items were created anyway'

    # Check that the user has no subscription
    assert_nil @user.subscription, "user's subscription was not found"
  end
end
