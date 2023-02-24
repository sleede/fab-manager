# frozen_string_literal: true

# A payment schedule applied to plan in the shopping cart
class CartItem::PaymentSchedule < ApplicationRecord
  self.table_name = 'cart_item_payment_schedules'

  belongs_to :customer_profile, class_name: 'InvoicingProfile'
  belongs_to :coupon
  belongs_to :plan

  def customer
    customer_profile.user
  end

  def schedule(total, total_without_coupon)
    schedule = if requested && plan&.monthly_payment
                 PaymentScheduleService.new.compute(plan, total_without_coupon, customer, coupon: coupon.coupon, start_at: start_at)
               else
                 nil
               end

    total_amount = if schedule
                     schedule[:items][0].amount
                   else
                     total
                   end

    { schedule: schedule, total: total_amount }
  end

  def type
    'subscription'
  end

  def valid?(_all_items)
    return true unless requested && plan&.monthly_payment

    if plan&.disabled
      errors.add(:plan, I18n.t('cart_item_validation.plan'))
      return false
    end
    true
  end
end
