# frozen_string_literal: true

# Validates that start_at is same or before end_at in the given record
class DateRangeValidator < ActiveModel::Validator
  def validate(record)
    the_end = record.start_at
    the_start = record.end_at
    return unless the_end.present? && the_end >= the_start

    record.errors[:end_at] << "The end date can't be before the start date. Pick a date after #{the_start}"
  end
end
