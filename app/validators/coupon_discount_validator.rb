class CouponDiscountValidator < ActiveModel::Validator
  def validate(record)
    if !record.percent_off.nil?
      unless (0..100).include? record.percent_off
        record.errors[:percent_off] << I18n.t('errors.messages.percentage_out_of_range')
      end
    elsif !record.amount_off.nil?
      unless record.amount_off > 0
        record.errors[:amount_off] << I18n.t('errors.messages.greater_than_or_equal_to', count: 0)
      end
    else
      record.errors[:percent_off] << I18n.t('errors.messages.cannot_be_blank_at_same_time', field: 'amount_off')
    end
  end
end