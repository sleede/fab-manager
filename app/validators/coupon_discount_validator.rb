# frozen_string_literal: true

# Validates the validity of a new or updated coupon
class CouponDiscountValidator < ActiveModel::Validator
  def validate(record)
    if !record.percent_off.nil?
      record.errors.add(:percent_off, I18n.t('errors.messages.percentage_out_of_range')) unless (0..100).include? record.percent_off
    elsif !record.amount_off.nil?
      record.errors.add(:amount_off, I18n.t('errors.messages.greater_than_or_equal_to', **{ count: 0 })) unless record.amount_off.positive?
    else
      record.errors.add(:percent_off, I18n.t('errors.messages.cannot_be_blank_at_same_time', **{ field: 'amount_off' }))
    end
  end
end
