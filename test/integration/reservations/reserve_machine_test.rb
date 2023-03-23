# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::ReserveMachineTest < ActionDispatch::IntegrationTest
  setup do
    @user_without_subscription = User.members.without_subscription.first
  end

  test 'user without subscription reserves a machine with success' do
    login_as(@user_without_subscription, scope: :user)

    machine = Machine.find(6)
    availability = Availability.find(4)
    slot = availability.slots.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    subscriptions_count = Subscription.count

    VCR.use_cassette('reservations_create_for_machine_without_subscription_success') do
      post '/api/stripe/confirm_payment',
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
    assert_equal users_credit_count, UsersCredit.count
    assert_equal subscriptions_count, Subscription.count

    # subscription assertions
    assert_equal 0, @user_without_subscription.subscriptions.count
    assert_nil @user_without_subscription.subscribed_plan

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert_equal machine.prices.find_by(group_id: @user_without_subscription.group_id, plan_id: nil).amount, invoice_item.amount
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
    cached = slot.places.detect { |p| p['reservable_id'] == machine.id && p['reservable_type'] == machine.class.name }
    assert_not_nil cached
    assert_equal 1, cached['reserved_places']
    assert_includes cached['user_ids'], @user_without_subscription.id
  end

  test 'user without subscription reserves a machine with error' do
    login_as(@user_without_subscription, scope: :user)

    machine = Machine.find(6)
    availability = Availability.find(4)

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    notifications_count = Notification.count

    VCR.use_cassette('reservations_create_for_machine_without_subscription_error') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method(error: :card_declined),
             cart_items: {
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

    # Check response format & status
    assert_equal 200, response.status, "API does not return the expected status. #{response.body}"
    assert_match Mime[:json].to_s, response.content_type

    # Check the error was handled
    assert_match(/Your card was declined/, response.body)

    # Check the subscription wasn't taken
    assert_equal reservations_count, Reservation.count
    assert_equal invoice_count, Invoice.count
    assert_equal invoice_items_count, InvoiceItem.count
    assert_equal notifications_count, Notification.count

    # subscription assertions
    assert_equal 0, @user_without_subscription.subscriptions.count
    assert_nil @user_without_subscription.subscribed_plan
  end

  test 'user reserves a machine and a subscription using a coupon with success' do
    login_as(@user_without_subscription, scope: :user)

    machine = Machine.find(6)
    plan = Plan.find(4)
    availability = Availability.find(4)

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    subscriptions_count = Subscription.count
    users_credit_count = UsersCredit.count

    VCR.use_cassette('reservations_machine_and_plan_using_coupon_success') do
      post '/api/stripe/confirm_payment',
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
               coupon_code: 'SUNNYFABLAB'
             }
           }.to_json, headers: default_headers
    end

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 2, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal subscriptions_count + 1, Subscription.count

    # subscription assertions
    assert_equal 1, @user_without_subscription.subscriptions.count
    assert_not_nil @user_without_subscription.subscribed_plan
    assert_equal plan.id, @user_without_subscription.subscribed_plan.id

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
    assert invoice.check_footprint

    # invoice_items assertions
    ## reservation
    reservation_item = invoice.invoice_items.find_by(object: reservation)

    assert_not_nil reservation_item
    assert_equal reservation_item.amount, machine.prices.find_by(group_id: @user_without_subscription.group_id, plan_id: plan.id).amount
    assert reservation_item.check_footprint
    ## subscription
    subscription_item = invoice.invoice_items.find_by(object_type: Subscription.name)

    assert_not_nil subscription_item

    subscription = subscription_item.object

    assert_equal subscription_item.amount, plan.amount
    assert_equal subscription.plan_id, plan.id
    assert subscription_item.check_footprint

    VCR.use_cassette('reservations_machine_and_plan_using_coupon_retrieve_invoice_from_stripe') do
      stp_intent = invoice.payment_gateway_object.gateway_object.retrieve
      assert_equal stp_intent.amount, invoice.total
    end

    # notifications
    assert_not_empty Notification.where(attached_object: reservation)
    assert_not_empty Notification.where(attached_object: subscription)
  end
end
