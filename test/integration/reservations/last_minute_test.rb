# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::LastMinuteTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.members.first
    @space = Space.first
    @availability = Availability.find(21)
    @admin = User.with_role(:admin).first
  end

  test 'user cannot reserve last minute booking' do
    Setting.set('space_reservation_deadline', '120')

    login_as(@user, scope: :user)

    VCR.use_cassette('last_minute_space_reservations_not_allowed') do
      post '/api/stripe/confirm_payment', params: {
        payment_method_id: stripe_payment_method,
        cart_items: {
          items: [
            {
              reservation: {
                reservable_id: @space.id,
                reservable_type: @space.class.name,
                slots_reservations_attributes: [
                  {
                    slot_id: @availability.slots.first.id
                  }
                ]
              }
            }
          ]
        }
      }.to_json, headers: default_headers
    end

    # general assertions
    assert_equal 422, response.status
    assert_match(I18n.t('cart_item_validation.deadline', **{ MINUTES: 120 }), response.body)
  end

  test 'user can reserve last minute booking' do
    Setting.set('space_reservation_deadline', '0')

    login_as(@user, scope: :user)

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    subscriptions_count = Subscription.count

    VCR.use_cassette('last_minute_space_reservations_allowed') do
      post '/api/stripe/confirm_payment', params: {
        payment_method_id: stripe_payment_method,
        cart_items: {
          items: [
            {
              reservation: {
                reservable_id: @space.id,
                reservable_type: @space.class.name,
                slots_reservations_attributes: [
                  {
                    slot_id: @availability.slots.first.id
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
  end

  test 'admin can reserve last minute booking anyway' do
    Setting.set('space_reservation_deadline', '120')

    login_as(@admin, scope: :user)

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    subscriptions_count = Subscription.count

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @user.id,
      items: [
        {
          reservation: {
            reservable_id: @space.id,
            reservable_type: @space.class.name,
            slots_reservations_attributes: [
              {
                slot_id: @availability.slots.first.id
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
    assert_equal subscriptions_count, Subscription.count
  end
end
