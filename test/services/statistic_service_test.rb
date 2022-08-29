# frozen_string_literal: true

require 'test_helper'

class StatisticServiceTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.members.without_subscription.first
    @admin = User.with_role(:admin).first
    login_as(@admin, scope: :user)
  end

  test 'build stats' do
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
    ::Statistics::BuilderService.generate_statistic({ start_date: DateTime.current.beginning_of_day,
                                                      end_date: DateTime.current.end_of_day })

    Stats::Machine.refresh_index!

    stat_booking = Stats::Machine.search(query: { bool: { must: [{ term: { date: DateTime.current.to_date.iso8601 } },
                                                                 { term: { type: 'booking' } }] } }).first
    assert_not_nil stat_booking
    assert_equal machine.friendly_id, stat_booking['subType']
    check_statistics_on_user(stat_booking)

    stat_hour = Stats::Machine.search(query: { bool: { must: [{ term: { date: DateTime.current.to_date.iso8601 } },
                                                              { term: { type: 'hour' } }] } }).first

    assert_not_nil stat_hour
    assert_equal machine.friendly_id, stat_hour['subType']
    check_statistics_on_user(stat_hour)

    Stats::Subscription.refresh_index!

    stat_subscription = Stats::Subscription.search(query: { bool: { must: [{ term: { date: DateTime.current.to_date.iso8601 } },
                                                                           { term: { type: plan.find_statistic_type.key } }] } }).first

    assert_not_nil stat_subscription
    assert_equal plan.find_statistic_type.key, stat_subscription['type']
    assert_equal plan.slug, stat_subscription['subType']
    assert_equal plan.id, stat_subscription['planId']
    assert_equal 1, stat_subscription['stat']
    check_statistics_on_user(stat_subscription)
  end

  def check_statistics_on_user(stat)
    assert_equal @user.statistic_profile.str_gender, stat['gender']
    assert_equal @user.statistic_profile.age.to_i, stat['age']
    assert_equal @user.statistic_profile.group.slug, stat['group']
  end
end
