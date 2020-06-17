# frozen_string_literal: true

# Asynchronously generate the statistics for the last passed day.
# This worker is triggered every nights, see schedule.yml
class StatisticWorker
  include Sidekiq::Worker

  def perform
    return unless Setting.get('statistics_module')

    StatisticService.new.generate_statistic
  end
end
