# frozen_string_literal: true

require 'test_helper'

class StatisticServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.members.without_subscription.first
    @admin = User.with_role(:admin).first
    login_as(@admin, scope: :user)
  end

  def test
    machine_stats_count = Stats::Machine.all.count
    subscription_stats_count = Stats::Subscription.all.count

    # Create a reservation to generate an invoice
    machine = Machine.find(1)
    slot = Availability.find(19).slots.first
    post '/api/local_payment/confirm_payment', params: {
      customer_id: @user.id,
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
    }.to_json, headers: default_headers

    # Create a subscription to generate another invoice
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan')
    post '/api/local_payment/confirm_payment',
         params: {
           customer_id: @user.id,
           items: [
             {
               subscription: {
                 plan_id: plan.id
               }
             }
           ]
         }.to_json, headers: default_headers

    # Build the stats for today, we expect the above invoices (reservation+subscription) to appear in the resulting stats
    StatisticService.new.generate_statistic(
      start_date: DateTime.current.beginning_of_day,
      end_date: DateTime.current.end_of_day
    )

    assert_equal machine_stats_count + 1, Stats::Machine.all.count
    assert_equal subscription_stats_count + 1, Stats::Subscription.all.count
  end
end
