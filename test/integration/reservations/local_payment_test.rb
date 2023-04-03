# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::LocalPaymentTest < ActionDispatch::IntegrationTest
  setup do
    @user_without_subscription = User.members.without_subscription.first
    @user_with_subscription = User.members.with_subscription.second
    @admin = User.with_role(:admin).first
    login_as(@admin, scope: :user)
  end

  test 'user without subscription reserves a machine with success' do
    machine = Machine.find(6)
    availability = machine.availabilities.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @user_without_subscription.id,
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
    }.to_json, headers: default_headers

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count

    # subscription assertions
    assert_equal 0, @user_without_subscription.subscriptions.count
    assert_nil @user_without_subscription.subscribed_plan

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice assertions
    invoice = reservation.original_invoice

    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert_equal machine.prices.find_by(group_id: @user_without_subscription.group_id, plan_id: nil).amount, invoice_item.amount

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    # notification
    assert_not_empty Notification.where(attached_object: reservation)
  end

  test 'user without subscription reserves a training with success' do
    training = Training.first
    availability = training.availabilities.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @user_without_subscription.id,
      items: [
        reservation: {
          reservable_id: training.id,
          reservable_type: training.class.name,
          slots_reservations_attributes: [
            {
              slot_id: availability.slots.first.id
            }
          ]
        }
      ]
    }.to_json, headers: default_headers

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

    # invoice assertions
    invoice = reservation.original_invoice

    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    # invoice_items
    invoice_item = InvoiceItem.last

    assert_equal invoice_item.amount, training.amount_by_group(@user_without_subscription.group_id).amount

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    # notification
    assert_not_empty Notification.where(attached_object: reservation)
  end

  test 'user with subscription reserves a machine with success' do
    plan = @user_with_subscription.subscribed_plan
    machine = Machine.find(6)
    availability = machine.availabilities.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @user_with_subscription.id,
      items: [
        {
          reservation: {
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            slots_reservations_attributes: [
              {
                slot_id: availability.slots.first.id
              },
              {
                slot_id: availability.slots.last.id
              }
            ]
          }
        }
      ]
    }.to_json, headers: default_headers

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 2, InvoiceItem.count
    assert_equal users_credit_count + 1, UsersCredit.count

    # subscription assertions
    assert_equal 1, @user_with_subscription.subscriptions.count
    assert_not_nil @user_with_subscription.subscribed_plan
    assert_equal plan.id, @user_with_subscription.subscribed_plan.id

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 2, reservation.original_invoice.invoice_items.count

    # invoice assertions
    invoice = reservation.original_invoice

    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?

    # invoice_items assertions
    invoice_items = InvoiceItem.last(2)
    machine_price = machine.prices.find_by(group_id: @user_with_subscription.group_id, plan_id: plan.id).amount

    assert(invoice_items.any? { |ii| ii.amount.zero? })
    assert(invoice_items.any? { |ii| ii.amount == machine_price })

    # users_credits assertions
    users_credit = UsersCredit.last

    assert_equal @user_with_subscription, users_credit.user
    assert_equal [reservation.slots.count, plan.machine_credits.find_by(creditable_id: machine.id).hours].min, users_credit.hours_used

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    # notification
    assert_not_empty Notification.where(attached_object: reservation)
  end

  test 'user reserves a training and a subscription with success' do
    training = Training.first
    availability = training.availabilities.first
    plan = Plan.where(group_id: @user_without_subscription.group.id, type: 'Plan').first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @user_without_subscription.id,
      items: [
        {
          reservation: {
            reservable_id: training.id,
            reservable_type: training.class.name,
            slots_reservations_attributes: [
              {
                slot_id: availability.slots.first.id,
                offered: false
              }
            ]
          }
        },
        {
          subscription: {
            plan_id: plan&.id
          }
        }
      ]
    }.to_json, headers: default_headers

    # general assertions
    assert_equal 201, response.status
    assert_match Mime[:json].to_s, response.content_type
    result = json_response(response.body)

    # Check the DB objects have been created as they should
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 2, InvoiceItem.count
    assert_equal users_credit_count + 1, UsersCredit.count

    # subscription assertions
    assert_equal 1, @user_without_subscription.subscriptions.count
    assert_not_nil @user_without_subscription.subscribed_plan
    assert_equal plan&.id, @user_without_subscription.subscribed_plan.id

    # reservation assertions
    invoice = Invoice.find(result[:id])
    reservation = invoice.main_item.object

    assert reservation.original_invoice
    assert_equal 2, reservation.original_invoice.invoice_items.count

    # credits assertions
    assert_equal 1, @user_without_subscription.credits.count
    assert_equal 'Training', @user_without_subscription.credits.last.creditable_type
    assert_equal training.id, @user_without_subscription.credits.last.creditable_id

    # invoice assertions
    invoice = reservation.original_invoice

    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert_equal plan&.amount, invoice.total

    # invoice_items
    invoice_items = InvoiceItem.last(2)

    assert(invoice_items.any? { |ii| ii.amount == plan&.amount && ii.object_type == Subscription.name })
    assert(invoice_items.any? { |ii| ii.amount.zero? })

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    # notification
    assert_not_empty Notification.where(attached_object: reservation)
  end
end
