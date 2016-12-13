class CouponExpirationValidator < ActiveModel::Validator
  ##
  # @param record {Coupon}
  ##
  def validate(record)
    previous = record.valid_until_was
    current = record.valid_until

    unless current.blank?
      if current.end_of_day < Time.now
        record.errors[:valid_until] << I18n.t('errors.messages.cannot_be_in_the_past')
      end

      if !previous.blank? and current.end_of_day < previous.end_of_day
        record.errors[:valid_until] << I18n.t('errors.messages.cannot_be_before_previous_value')
      end
    end
  end
end