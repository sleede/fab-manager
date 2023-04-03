# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::PayWithWalletTest < ActionDispatch::IntegrationTest
  setup do
    @vlonchamp = User.find_by(username: 'vlonchamp')
  end

  test 'user reserves a machine and pay by wallet with success' do
    login_as(@vlonchamp, scope: :user)

    machine = Machine.find(6)
    availability = Availability.find(4)

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    wallet_transactions_count = WalletTransaction.count

    VCR.use_cassette('reservations_create_for_machine_and_pay_wallet_success') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               customer_id: @vlonchamp.id,
               items: [
                 {
                   reservation: {
                     reservable_id: machine.id,
                     reservable_type: machine.class.name,
                     slots_reservations_attributes: [
                       {
                         slot_id: availability.slots.first.id
                       }
                     ]
                   }
                 }
               ]
             }
           }.to_json, headers: default_headers
    end

    @vlonchamp.wallet.reload

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal wallet_transactions_count + 1, WalletTransaction.count

    # subscription assertions
    assert_equal 0, @vlonchamp.subscriptions.count
    assert_nil @vlonchamp.subscribed_plan

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert_equal machine.prices.find_by(group_id: @vlonchamp.group_id, plan_id: nil).amount, invoice_item.amount
    assert invoice_item.check_footprint

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    assert_not invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: reservation)

    # wallet
    assert_equal 0, @vlonchamp.wallet.amount
    assert_equal 2, @vlonchamp.wallet.wallet_transactions.count
    transaction = @vlonchamp.wallet.wallet_transactions.last
    assert_equal 'debit', transaction.transaction_type
    assert_equal 10, transaction.amount
    assert_equal invoice.wallet_amount / 100.0, transaction.amount
  end

  test 'user reserves a training and a subscription by wallet with success' do
    login_as(@vlonchamp, scope: :user)

    training = Training.first
    availability = training.availabilities.first
    plan = Plan.find_by(group_id: @vlonchamp.group.id, type: 'Plan', base_name: 'Mensuel tarif réduit')

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    wallet_transactions_count = WalletTransaction.count

    VCR.use_cassette('reservations_create_for_training_and_plan_by_pay_wallet_success') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               items: [
                 {
                   reservation: {
                     reservable_id: training.id,
                     reservable_type: training.class.name,
                     slots_reservations_attributes: [
                       {
                         slot_id: availability.slots.first.id
                       }
                     ]
                   }
                 },
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

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 2, InvoiceItem.count
    assert_equal wallet_transactions_count + 1, WalletTransaction.count

    # subscription assertions
    assert_equal 1, @vlonchamp.subscriptions.count
    assert_not_nil @vlonchamp.subscribed_plan
    assert_equal plan.id, @vlonchamp.subscribed_plan.id

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 2, reservation.original_invoice.invoice_items.count

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    assert_not invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert_equal invoice.total, 2000
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: reservation)

    # wallet
    assert_equal 0, @vlonchamp.wallet.amount
    assert_equal 2, @vlonchamp.wallet.wallet_transactions.count
    transaction = @vlonchamp.wallet.wallet_transactions.last
    assert_equal 'debit', transaction.transaction_type
    assert_equal 10, transaction.amount
    assert_equal invoice.wallet_amount / 100.0, transaction.amount
  end

  test 'user reserves a machine and renew a subscription with payment schedule and coupon and wallet' do
    user = User.find_by(username: 'lseguin')
    login_as(user, scope: :user)

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    subscriptions_count = Subscription.count
    user_subscriptions_count = user.subscriptions.count
    payment_schedule_count = PaymentSchedule.count
    payment_schedule_items_count = PaymentScheduleItem.count
    wallet_transactions_count = WalletTransaction.count

    machine = Machine.find(1)
    slots = Availabilities::AvailabilitiesService.new(user)
                                                 .machines([machine], user, { start: Time.current, end: 1.day.from_now })
    plan = Plan.find_by(group_id: user.group.id, type: 'Plan', base_name: 'Abonnement mensualisable')

    VCR.use_cassette('reservations_machine_subscription_with_payment_schedule_coupon_wallet') do
      post '/api/stripe/setup_subscription',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               items: [
                 {
                   reservation: {
                     reservable_id: machine.id,
                     reservable_type: machine.class.name,
                     slots_reservations_attributes: [
                       {
                         slot_id: slots.first.id
                       }
                     ]
                   }
                 },
                 {
                   subscription: {
                     plan_id: plan.id
                   }
                 }
               ],
               payment_schedule: true,
               payment_method: 'card',
               coupon_code: 'GIME3EUR'
             }
           }.to_json, headers: default_headers

      # Check response format & status
      assert_equal 201, response.status, response.body
      assert_match Mime[:json].to_s, response.content_type

      # Check the response
      res = json_response(response.body)
      assert_not_nil res[:id]
    end

    assert_equal reservations_count + 1, Reservation.count, 'missing the reservation'
    assert_equal invoice_count, Invoice.count, "an invoice was generated but it shouldn't"
    assert_equal invoice_items_count, InvoiceItem.count, "some invoice items were generated but they shouldn't"
    assert_equal 0, UsersCredit.count, "user's credits were not reset"
    assert_equal subscriptions_count + 1, Subscription.count, 'missing the subscription'
    assert_equal payment_schedule_count + 1, PaymentSchedule.count, 'missing the payment schedule'
    assert_equal payment_schedule_items_count + 12, PaymentScheduleItem.count, 'missing some payment schedule items'
    assert_equal wallet_transactions_count + 1, WalletTransaction.count, 'missing the wallet transaction'

    # get the objects
    reservation = Reservation.last
    subscription = Subscription.last
    payment_schedule = PaymentSchedule.last

    # subscription assertions
    assert_equal user_subscriptions_count + 1, user.subscriptions.count
    assert_equal user, subscription.user
    assert_not_nil user.subscribed_plan, "user's subscribed plan was not found"
    assert_not_nil user.subscription, "user's subscription was not found"
    assert_equal plan.id, user.subscribed_plan.id, "user's plan does not match"

    # reservation assertions
    assert reservation.original_payment_schedule
    assert_equal payment_schedule.main_object.object, reservation

    # payment schedule assertions
    assert_not_nil payment_schedule.reference
    assert_equal 'card', payment_schedule.payment_method
    assert_equal 2, payment_schedule.payment_gateway_objects.count
    assert_not_nil payment_schedule.gateway_payment_mean
    assert_not_nil payment_schedule.wallet_transaction
    assert_equal CouponService.new.apply(payment_schedule.ordered_items.first.amount, payment_schedule.coupon, user.id),
                 payment_schedule.wallet_amount
    assert_equal Coupon.find_by(code: 'GIME3EUR').id, payment_schedule.coupon_id
    assert_equal 'test', payment_schedule.environment
    assert payment_schedule.check_footprint
    assert_equal user.invoicing_profile.id, payment_schedule.invoicing_profile_id
    assert_equal payment_schedule.invoicing_profile_id, payment_schedule.operator_profile_id

    # Check the answer
    result = json_response(response.body)
    assert_equal payment_schedule.id, result[:id], 'payment schedule id does not match'
    subscription = payment_schedule.payment_schedule_objects.find { |pso| pso.object_type == Subscription.name }&.object
    assert_equal plan.id, subscription&.plan_id, 'subscribed plan does not match'
  end
end
