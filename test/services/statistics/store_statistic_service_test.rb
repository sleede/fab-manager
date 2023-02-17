# frozen_string_literal: true

require 'test_helper'

class StoreStatisticServiceTest < ActionDispatch::IntegrationTest
  setup do
    @order = Order.find(15)
  end

  test 'build stats about orders' do
    # Build the stats for the last 3 days, we expect the above invoices (reservations+subscription) to appear in the resulting stats
    ::Statistics::BuilderService.generate_statistic({ start_date: Time.current.beginning_of_day,
                                                      end_date: Time.current.end_of_day })

    Stats::Order.refresh_index!

    # we should find order id 15 (created today)
    stat_order = Stats::Order.search(query: { bool: { must: [{ term: { date: Time.current.to_date.iso8601 } },
                                                             { term: { type: 'store' } }] } }).first
    assert_not_nil stat_order
    assert_equal @order.id, stat_order['orderId']
    check_statistics_on_user(stat_order)
  end

  def check_statistics_on_user(stat)
    assert_equal @order.statistic_profile.str_gender, stat['gender']
    assert_equal @order.statistic_profile.age.to_i, stat['age']
    assert_equal @order.statistic_profile.group.slug, stat['group']
  end
end
