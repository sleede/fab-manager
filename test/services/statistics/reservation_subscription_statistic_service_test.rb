# frozen_string_literal: true

require 'test_helper'

class ReservationSubscriptionStatisticServiceTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.members.without_subscription.first
    @admin = User.with_role(:admin).first
    login_as(@admin, scope: :user)
  end

  test 'build default stats' do
    ::Statistics::BuilderService.generate_statistic
  end

  test 'build stats' do
    # Create a reservation to generate an invoice (2 days ago)
    machine = Machine.find(1)
    slot = Availability.find(19).slots.first
    travel_to(2.days.ago)
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
    travel_back

    # Create a subscription to generate another invoice (1 day ago)
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan')
    travel_to(1.day.ago)
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

    # Create a training reservation (1 day ago)
    training = Training.find(1)
    tr_slot = Availability.find(2).slots.first
    post '/api/local_payment/confirm_payment', params: {
      customer_id: @user.id,
      items: [
        {
          reservation: {
            reservable_id: training.id,
            reservable_type: training.class.name,
            slots_reservations_attributes: [
              {
                slot_id: tr_slot.id
              }
            ]
          }
        }
      ]
    }.to_json, headers: default_headers
    travel_back

    # Crate another machine reservation (today)
    slot = Availability.find(19).slots.last
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

    Stats::Machine.refresh_index!
    Stats::Training.refresh_index!
    Stats::Subscription.refresh_index!

    # Build the stats for the last 3 days, we expect the above invoices (reservations+subscription) to appear in the resulting stats
    ::Statistics::BuilderService.generate_statistic({ start_date: 2.days.ago.beginning_of_day,
                                                      end_date: DateTime.current.end_of_day })

    Stats::Machine.refresh_index!

    # first machine reservation (2 days ago)
    stat_booking = Stats::Machine.search(query: { bool: { must: [{ term: { date: 2.days.ago.to_date.iso8601 } },
                                                                 { term: { type: 'booking' } }] } }).first
    assert_not_nil stat_booking
    assert_equal machine.friendly_id, stat_booking['subType']
    check_statistics_on_user(stat_booking)

    stat_hour = Stats::Machine.search(query: { bool: { must: [{ term: { date: 2.days.ago.to_date.iso8601 } },
                                                              { term: { type: 'hour' } }] } }).first

    assert_not_nil stat_hour
    assert_equal machine.friendly_id, stat_hour['subType']
    check_statistics_on_user(stat_hour)

    # second machine reservation (today)
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

    # training
    Stats::Training.refresh_index!

    stat_training = Stats::Training.search(query: { bool: { must: [{ term: { date: 1.day.ago.to_date.iso8601 } },
                                                                   { term: { type: 'booking' } }] } }).first
    assert_not_nil stat_training
    assert_equal training.friendly_id, stat_training['subType']
    check_statistics_on_user(stat_training)

    # subscription
    Stats::Subscription.refresh_index!

    stat_subscription = Stats::Subscription.search(query: { bool: { must: [{ term: { date: 1.day.ago.to_date.iso8601 } },
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
