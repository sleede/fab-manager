# frozen_string_literal: true

# module grouping all statistics concerns
module Statistics::Concerns; end

# Provides various helpers for services dealing with statistics generation
module Statistics::Concerns::HelpersConcern
  extend ActiveSupport::Concern

  class_methods do
    def default_options
      yesterday = 1.day.ago
      {
        start_date: yesterday.beginning_of_day,
        end_date: yesterday.end_of_day
      }
    end

    def format_date(date)
      if date.is_a?(String)
        Date.strptime(date, '%Y%m%d').strftime('%Y-%m-%d')
      else
        date.strftime('%Y-%m-%d')
      end
    end

    def user_info_stat(stat)
      {
        userId: stat[:user_id],
        gender: stat[:gender],
        age: stat[:age],
        group: stat[:group]
      }
    end

    def difference_in_hours(start_at, end_at)
      if start_at.to_date == end_at.to_date
        ((end_at - start_at) / 60 / 60).to_i
      else
        end_at_to_start_date = end_at.change(year: start_at.year, month: start_at.month, day: start_at.day)
        hours = ((end_at_to_start_date - start_at) / 60 / 60).to_i
        hours = ((end_at.to_date - start_at.to_date).to_i + 1) * hours if end_at.to_date > start_at.to_date
        hours
      end
    end
  end
end
