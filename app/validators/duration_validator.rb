# frozen_string_literal: true

# Validates that the duration between start_at and end_at is between 1 day and 1 year
class DurationValidator < ActiveModel::Validator
  def validate(record)
    the_end = record.end_at
    the_start = record.start_at
    diff = (the_end - the_start).to_i
    return if diff.days >= 1.day && diff.days <= 1.year

    record.errors[:end_at] << I18n.t('errors.messages.invalid_duration', DAYS: diff)
  end
end
