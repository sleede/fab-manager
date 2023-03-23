# frozen_string_literal: true

require 'test_helper'

module Reservations; end

class Reservations::PaymentScheduleTest < ActionDispatch::IntegrationTest
  setup do
    @user_without_subscription = User.members.without_subscription.first
    @admin = User.with_role(:admin).first
    login_as(@admin, scope: :user)
  end

  test 'user reserves a training and a subscription with payment schedule' do
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

    VCR.use_cassette('reservations_admin_training_subscription_with_payment_schedule') do
      post '/api/local_payment/confirm_payment', params: {
        payment_method: 'check',
        payment_schedule: true,
        customer_id: @user_without_subscription.id,
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
      }.to_json, headers: default_headers
    end

    # get the objects
    reservation = Reservation.last
    payment_schedule = PaymentSchedule.last

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

    # subscription assertions
    assert_equal 1, @user_without_subscription.subscriptions.count
    assert_not_nil @user_without_subscription.subscribed_plan, "user's subscribed plan was not found"
    assert_not_nil @user_without_subscription.subscription, "user's subscription was not found"
    assert_equal plan.id, @user_without_subscription.subscribed_plan.id, "user's plan does not match"

    # payment schedule assertions
    assert reservation.original_payment_schedule
    assert_equal payment_schedule.id, reservation.original_payment_schedule.id
    assert_not_nil payment_schedule.reference
    assert_equal 'check', payment_schedule.payment_method
    assert_empty payment_schedule.payment_gateway_objects
    assert_nil payment_schedule.wallet_transaction
    assert_nil payment_schedule.wallet_amount
    assert_nil payment_schedule.coupon_id
    assert_equal 'test', payment_schedule.environment
    assert payment_schedule.check_footprint, payment_schedule.debug_footprint
    assert_equal @user_without_subscription.invoicing_profile.id, payment_schedule.invoicing_profile_id
    assert_equal @admin.invoicing_profile.id, payment_schedule.operator_profile_id
    assert_schedule_pdf(payment_schedule)

    # Check the answer
    result = json_response(response.body)
    assert_equal reservation.original_payment_schedule.id, result[:id], 'payment schedule id does not match'

    # reservation assertions
    assert_equal result[:main_object][:id], reservation.id
    assert_equal payment_schedule.main_object.object, reservation
  end
end
