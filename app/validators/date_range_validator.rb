# frozen_string_literal: true

# Validates that start_at is same or before end_at in the given record
class DateRangeValidator < ActiveModel::Validator
  def validate(record)
    the_end = record.end_at
    the_start = record.start_at
    return if the_end.present? && the_end >= the_start

    record.errors.add(:end_at, I18n.t('errors.messages.end_before_start', **{ START: the_start }))
  end
end
