# frozen_string_literal: true

# Validates the current period is strictly in the past
class PastPeriodValidator < ActiveModel::Validator
  def validate(record)
    the_end = record.end_at

    return if the_end.present? && the_end < Time.zone.today

    record.errors.add(:end_at, I18n.t('errors.messages.must_be_in_the_past'))
  end
end
