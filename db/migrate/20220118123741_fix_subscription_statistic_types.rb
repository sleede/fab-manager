# frozen_string_literal: true

# From Fab-manager v4.3.3, the behavior of ActiveSupport::Duration#to_i has changed.
# Previously, a month = 30 days, from since a month = 30.436875 days.
# Also, previously a year = 365.25 days, from since a year = 365.2425 days.
# This introduced a bug due to the key of the statistic types for subscriptions were equal to
# the number of seconds of the plan duration, but this duration has changed due to the
# change reported above.
# This migration fixes the problem by changing the key of the statistic types for subscriptions
# to the new plans durations.
class FixSubscriptionStatisticTypes < ActiveRecord::Migration[5.2]
  def up
    one_month = 2_592_000
    (1..12).each do |n|
      StatisticType.where(key: (one_month * n).to_s).update_all(key: n.months.to_i)
    end
    one_year = 31_557_600
    (1..10).each do |n|
      StatisticType.where(key: (one_year * n).to_s).update_all(key: n.years.to_i)
    end
  end

  def down
    one_month = 2_592_000
    (1..12).each do |n|
      StatisticType.where(key: n.months.to_i.to_s).update_all(key: (one_month * n).to_i)
    end
    one_year = 31_557_600
    (1..10).each do |n|
      StatisticType.where(key: n.years.to_i).update_all(key: (one_year * n).to_s)
    end
  end
end
