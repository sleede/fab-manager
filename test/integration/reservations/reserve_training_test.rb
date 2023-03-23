# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::ReserveTrainingTest < ActionDispatch::IntegrationTest
  setup do
    @user_without_subscription = User.members.without_subscription.first
  end

  test 'user without subscription reserves a training with success' do
    login_as(@user_without_subscription, scope: :user)

    training = Training.first
    availability = training.availabilities.first
    slot = availability.slots.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count

    VCR.use_cassette('reservations_create_for_training_without_subscription_success') do
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
                         slot_id: slot.id
                       }
                     ]
                   }
                 }
               ]
             }
           }.to_json, headers: default_headers
    end

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count

    # subscription assertions
    assert_equal 0, @user_without_subscription.subscriptions.count
    assert_nil @user_without_subscription.subscribed_plan

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice_items
    invoice_item = InvoiceItem.last

    assert_equal invoice_item.amount, training.amount_by_group(@user_without_subscription.group_id).amount
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

    # place cache
    slot.reload
    cached = slot.places.detect { |p| p['reservable_id'] == training.id && p['reservable_type'] == training.class.name }
    assert_not_nil cached
    assert_equal 1, cached['reserved_places']
    assert_includes cached['user_ids'], @user_without_subscription.id
  end

  test 'user reserves a training with an expired coupon with error' do
    login_as(@user_without_subscription, scope: :user)

    training = Training.find(1)
    availability = training.availabilities.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    notifications_count = Notification.count

    VCR.use_cassette('reservations_training_with_expired_coupon_error') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               customer_id: @user_without_subscription.id,
               items: [
                 {
                   reservation: {
                     reservable_id: training.id,
                     reservable_type: training.class.name,
                     card_token: stripe_payment_method,
                     slots_reservations_attributes: [
                       {
                         slot_id: availability.slots.first.id
                       }
                     ]
                   }
                 }
               ],
               coupon_code: 'XMAS10'
             }
           }.to_json, headers: default_headers
    end

    # general assertions
    assert_equal 422, response.status
    assert_equal reservations_count, Reservation.count
    assert_equal invoice_count, Invoice.count
    assert_equal invoice_items_count, InvoiceItem.count
    assert_equal notifications_count, Notification.count

    # subscription assertions
    assert_equal 0, @user_without_subscription.subscriptions.count
    assert_nil @user_without_subscription.subscribed_plan
  end

  test 'user reserves a training and a subscription with payment schedule' do
    login_as(@user_without_subscription, scope: :user)

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    subscriptions_count = Subscription.count
    users_credit_count = UsersCredit.count
    payment_schedule_count = PaymentSchedule.count
    payment_schedule_items_count = PaymentScheduleItem.count

    training = Training.find(1)
    availability = training.availabilities.first
    plan = Plan.find_by(group_id: @user_without_subscription.group.id, type: 'Plan', base_name: 'Abonnement mensualisable')

    VCR.use_cassette('reservations_training_subscription_with_payment_schedule') do
      post '/api/stripe/setup_subscription',
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
               ],
               payment_schedule: true,
               payment_method: 'cart'
             }
           }.to_json, headers: default_headers

      # Check response format & status
      assert_equal 201, response.status, response.body
      assert_match Mime[:json].to_s, response.content_type

      # Check the response
      sub = json_response(response.body)
      assert_not_nil sub[:id]
    end

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type
    assert_equal reservations_count + 1, Reservation.count, 'missing the reservation'
    assert_equal invoice_count, Invoice.count, "an invoice was generated but it shouldn't"
    assert_equal invoice_items_count, InvoiceItem.count, "some invoice items were generated but they shouldn't"
    assert_equal users_credit_count, UsersCredit.count, "user's credits count has changed but it shouldn't"
    assert_equal subscriptions_count + 1, Subscription.count, 'missing the subscription'
    assert_equal payment_schedule_count + 1, PaymentSchedule.count, 'missing the payment schedule'
    assert_equal payment_schedule_items_count + 12, PaymentScheduleItem.count, 'missing some payment schedule items'

    # get the objects
    reservation = Reservation.last
    payment_schedule = PaymentSchedule.last

    # subscription assertions
    assert_equal 1, @user_without_subscription.subscriptions.count
    assert_not_nil @user_without_subscription.subscribed_plan, "user's subscribed plan was not found"
    assert_not_nil @user_without_subscription.subscription, "user's subscription was not found"
    assert_equal plan.id, @user_without_subscription.subscribed_plan.id, "user's plan does not match"

    # reservation assertions
    assert reservation.original_payment_schedule
    assert_equal payment_schedule.main_object.object, reservation

    # Check the answer
    result = json_response(response.body)
    assert_equal payment_schedule.id, result[:id], 'payment schedule id does not match'
    subscription = payment_schedule.payment_schedule_objects.find { |pso| pso.object_type == Subscription.name }.object
    assert_equal plan.id, subscription.plan_id, 'subscribed plan does not match'
  end
end
