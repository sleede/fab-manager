# frozen_string_literal: true

# Asynchronously generate the statistics for the given period
# This worker is triggered when enabling the statistics and with `rails fablab:es:generate_stats`
class PeriodStatisticsWorker
  include Sidekiq::Worker

  # @param period {String|Integer} date string or number of days until current date
  def perform(period)
    days = date_to_days(period)
    Rails.logger.info "\n==> generating statistics for the last #{days} days <==\n"
    if days.zero?
      Statistics::BuilderService.generate_statistic(start_date: Time.current.beginning_of_day, end_date: Time.current.end_of_day)
    else
      days.times.each do |i|
        Statistics::BuilderService.generate_statistic(start_date: i.day.ago.beginning_of_day, end_date: i.day.ago.end_of_day)
      end
    end
  end

  def date_to_days(value)
    return value.to_i if number?(value)

    date = Date.parse(value.to_s)
    (Time.current.to_date - date).to_i
  end

  def number?(string)
    true if Float(string)
  rescue StandardError
    false
  end
end
