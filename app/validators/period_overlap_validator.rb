# frozen_string_literal: true

# Validates the current accounting period does not overlap an existing one
class PeriodOverlapValidator < ActiveModel::Validator
  def validate(record)
    the_end = record.end_at
    the_start = record.start_at

    AccountingPeriod.all.each do |period|
      if the_start >= period.start_at && the_start <= period.end_at
        record.errors[:start_at] << I18n.t('errors.messages.cannot_overlap')
      end
      if the_end >= period.start_at && the_end <= period.end_at
        record.errors[:end_at] << I18n.t('errors.messages.cannot_overlap')
      end
      if period.start_at >= the_start && period.end_at <= the_end
        record.errors[:end_at] << I18n.t('errors.messages.cannot_encompass')
      end
    end
  end
end
