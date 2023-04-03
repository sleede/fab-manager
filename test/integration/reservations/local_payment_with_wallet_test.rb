# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::LocalPaymentWithWalletTest < ActionDispatch::IntegrationTest
  setup do
    @vlonchamp = User.find_by(username: 'vlonchamp')
    @admin = User.with_role(:admin).first
    login_as(@admin, scope: :user)
  end

  test 'user reserves a machine and a subscription pay by wallet with success' do
    machine = Machine.find(6)
    availability = machine.availabilities.first
    plan = Plan.find_by(group_id: @vlonchamp.group.id, type: 'Plan', base_name: 'Mensuel tarif réduit')

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    wallet_transactions_count = WalletTransaction.count

    post '/api/local_payment/confirm_payment', params: {
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
        },
        {
          subscription: {
            plan_id: plan.id
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
    invoice = reservation.original_invoice

    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert_equal invoice.total, 2000

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    # notification
    assert_not_empty Notification.where(attached_object: reservation)

    # wallet
    assert_equal @vlonchamp.wallet.amount, 0
    assert_equal @vlonchamp.wallet.wallet_transactions.count, 2
    transaction = @vlonchamp.wallet.wallet_transactions.last
    assert_equal transaction.transaction_type, 'debit'
    assert_equal transaction.amount, 10
    assert_equal transaction.amount, invoice.wallet_amount / 100.0
    assert_equal transaction.id, invoice.wallet_transaction_id
  end

  test 'user without subscription reserves a machine and pay wallet with success' do
    machine = Machine.find(6)
    availability = machine.availabilities.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count

    post '/api/local_payment/confirm_payment', params: {
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
    }.to_json, headers: default_headers

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count

    # subscription assertions
    assert_equal 0, @vlonchamp.subscriptions.count
    assert_nil @vlonchamp.subscribed_plan

    # reservation assertions
    reservation = Reservation.last

    assert_not_nil reservation.original_invoice

    # notification
    assert_not_empty Notification.where(attached_object: reservation)
  end

  test 'user without subscription reserves a machine and pay by wallet with success' do
    machine = Machine.find(6)
    availability = machine.availabilities.first

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count

    post '/api/local_payment/confirm_payment', params: {
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
    }.to_json, headers: default_headers

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count

    # subscription assertions
    assert_equal 0, @vlonchamp.subscriptions.count
    assert_nil @vlonchamp.subscribed_plan

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

    assert_equal machine.prices.find_by(group_id: @vlonchamp.group_id, plan_id: nil).amount, invoice_item.amount

    # invoice assertions
    item = InvoiceItem.find_by(object: reservation)
    invoice = item.invoice
    assert_invoice_pdf invoice

    # notification
    assert_not_empty Notification.where(attached_object: reservation)

    # wallet
    assert_equal @vlonchamp.wallet.amount, 0
    assert_equal @vlonchamp.wallet.wallet_transactions.count, 2
    transaction = @vlonchamp.wallet.wallet_transactions.last
    assert_equal transaction.transaction_type, 'debit'
    assert_equal transaction.amount, 10
    assert_equal transaction.amount, invoice.wallet_amount / 100.0
    assert_equal transaction.id, invoice.wallet_transaction_id
  end
end
