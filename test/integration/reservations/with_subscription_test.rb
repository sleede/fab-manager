# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::WithSubscriptionTest < ActionDispatch::IntegrationTest
  setup do
    @user_with_subscription = User.members.with_subscription.second
  end

  test 'user with subscription reserves a machine with success' do
    login_as(@user_with_subscription, scope: :user)

    plan = @user_with_subscription.subscribed_plan
    machine = Machine.find(6)
    availability = Availability.find(4)

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count

    VCR.use_cassette('reservations_create_for_machine_with_subscription_success') do
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
                       },
                       {
                         slot_id: availability.slots.last.id
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

    # invoice_items assertions
    invoice_items = InvoiceItem.last(2)
    machine_price = machine.prices.find_by(group_id: @user_with_subscription.group_id, plan_id: plan.id).amount

    assert(invoice_items.any? { |inv| inv.amount.zero? })
    assert(invoice_items.any? { |inv| inv.amount == machine_price })
    assert(invoice_items.all?(&:check_footprint))

    # users_credits assertions
    users_credit = UsersCredit.last

    assert_equal @user_with_subscription, users_credit.user
    assert_equal [reservation.slots.count, plan.machine_credits.find_by(creditable_id: machine.id).hours].min, users_credit.hours_used

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    assert_not invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: reservation)
  end

  test 'user with subscription reserves the FIRST training with success' do
    login_as(@user_with_subscription, scope: :user)
    plan = @user_with_subscription.subscribed_plan
    plan.update!(is_rolling: true)

    training = Training.joins(credits: :plan).where(credits: { plan: plan }).first
    availability = training.availabilities.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count

    VCR.use_cassette('reservations_create_for_training_with_subscription_success') do
      post '/api/local_payment/confirm_payment',
           params: {
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
               }
             ]
           }.to_json, headers: default_headers
    end

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count

    # subscription assertions
    assert_equal 1, @user_with_subscription.subscriptions.count
    assert_not_nil @user_with_subscription.subscribed_plan
    assert_equal plan.id, @user_with_subscription.subscribed_plan.id

    # reservation assertions
    reservation = Reservation.last

    assert reservation.original_invoice
    assert_equal 1, reservation.original_invoice.invoice_items.count

    # invoice_items
    invoice_item = InvoiceItem.last

    assert_equal 0, invoice_item.amount # amount is 0 because this training is a credited training with that plan
    assert invoice_item.check_footprint

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: reservation)

    # check that user subscription were extended
    assert_equal reservation.slots.first.start_at + plan.duration, @user_with_subscription.subscription.expired_at
  end

  test 'user reserves a machine and pay by wallet with success' do
    @vlonchamp = User.find_by(username: 'vlonchamp')
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
    assert invoice_item.check_footprint, invoice_item.debug_footprint

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
end
