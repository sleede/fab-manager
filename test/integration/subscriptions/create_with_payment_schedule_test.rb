# frozen_string_literal: true

require 'test_helper'

module Subscriptions; end

class Subscriptions::CreateWithPaymentScheduleTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.find_by(username: 'jdupond')
    login_as(@user, scope: :user)
  end

  test 'user takes a subscription with payment schedule' do
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan', base_name: 'Abonnement mensualisable')
    payment_schedule_count = PaymentSchedule.count
    payment_schedule_items_count = PaymentScheduleItem.count

    VCR.use_cassette('subscriptions_user_create_with_payment_schedule') do
      post '/api/stripe/setup_subscription',
           params: {
             payment_method_id: stripe_payment_method,
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
      assert_equal 201, response.status, response.body
      assert_match Mime[:json].to_s, response.content_type

      # Check the response
      sub = json_response(response.body)
      assert_not_nil sub[:id]
    end

    # Check generalities
    assert_equal payment_schedule_count + 1, PaymentSchedule.count, 'missing the payment schedule'
    assert_equal payment_schedule_items_count + 12, PaymentScheduleItem.count, 'missing some payment schedule items'

    # Check the correct plan was subscribed
    result = json_response(response.body)
    assert_equal PaymentSchedule.last.id, result[:id], 'payment schedule id does not match'
    subscription = PaymentSchedule.find(result[:id]).payment_schedule_objects.first.object
    assert_equal plan.id, subscription.plan_id, 'subscribed plan does not match'

    # Check that the user has the correct subscription
    assert_not_nil @user.subscription, "user's subscription was not found"
    assert_not_nil @user.subscription.plan, "user's subscribed plan was not found"
    assert_equal plan.id, @user.subscription.plan_id, "user's plan does not match"
  end
end
