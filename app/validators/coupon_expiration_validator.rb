# frozen_string_literal: true

# Check that the expiration date of the given coupon is a valid value
class CouponExpirationValidator < ActiveModel::Validator
  ##
  # @param record {Coupon}
  ##
  def validate(record)
    previous = record.valid_until_was
    current = record.valid_until
    return if current.blank?

    record.errors.add(:valid_until, I18n.t('errors.messages.cannot_be_in_the_past')) if current.end_of_day < Time.current
    return unless previous.present? && current.end_of_day < previous.end_of_day

    record.errors.add(:valid_until, I18n.t('errors.messages.cannot_be_before_previous_value'))
  end
end
