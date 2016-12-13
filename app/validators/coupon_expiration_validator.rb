class CouponExpirationValidator < ActiveModel::Validator
  ##
  # @param record {Coupon}
  ##
  def validate(record)
    previous = record.valid_until_was
    current = record.valid_until

    unless current.blank?
      if current.end_of_day < Time.now
        record.errors[:valid_until] << 'New expiration date cannot be in the past'
      end

      if !previous.blank? and current.end_of_day < previous.end_of_day
        record.errors[:valid_until] << 'New expiration date cannot be before the previous one'
      end
    end
  end
end