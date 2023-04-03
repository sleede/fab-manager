# frozen_string_literal: true

# Validates that the duration between start_at and end_at is between 1 day and 1 year
class DurationValidator < ActiveModel::Validator
  def validate(record)
    the_end = record.end_at
    the_start = record.start_at
    diff = (the_end - the_start).to_i
    # 0.day means that (the_start == the_end), so it's a one day period
    return if diff.days >= 0.days && diff.days <= 1.year

    record.errors.add(:end_at, I18n.t('errors.messages.invalid_duration', **{ DAYS: diff }))
  end
end
