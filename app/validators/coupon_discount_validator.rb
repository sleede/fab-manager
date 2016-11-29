class CouponDiscountValidator < ActiveModel::Validator
  def validate(record)
    if !record.percent_off.nil?
      unless [0..100].include? record.percent_off
        record.errors[:percent_off] << 'Percentage must be included between 0 and 100'
      end
    elsif !record.amount_off.nil?
      unless record.amount_off > 0
        record.errors[:amount_off] << I18n.t('errors.messages.greater_than_or_equal_to', count: 0)
      end
    else
      record.errors[:percent_off] << 'cannot be blank when amount_off is blank too'
    end
  end
end