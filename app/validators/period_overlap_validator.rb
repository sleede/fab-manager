# frozen_string_literal: true

# Validates the current accounting period does not overlap an existing one
class PeriodOverlapValidator < ActiveModel::Validator
  def validate(record)
    the_end = record.end_at
    the_start = record.start_at

    AccountingPeriod.find_each do |period|
      record.errors.add(:start_at, I18n.t('errors.messages.cannot_overlap')) if the_start >= period.start_at && the_start <= period.end_at
      record.errors.add(:end_at, I18n.t('errors.messages.cannot_overlap')) if the_end >= period.start_at && the_end <= period.end_at
      record.errors.add(:end_at, I18n.t('errors.messages.cannot_encompass')) if period.start_at >= the_start && period.end_at <= the_end
    end
  end
end
