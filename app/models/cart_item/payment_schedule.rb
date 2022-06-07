# frozen_string_literal: true

# A payment schedule applied to plan in the shopping cart
class CartItem::PaymentSchedule
  attr_reader :requested, :errors

  def initialize(plan, coupon, requested, customer, start_at = nil)
    raise TypeError unless coupon.is_a? CartItem::Coupon

    @plan = plan
    @coupon = coupon
    @requested = requested
    @customer = customer
    @start_at = start_at
    @errors = {}
  end

  def schedule(total, total_without_coupon)
    schedule = if @requested && @plan&.monthly_payment
                 PaymentScheduleService.new.compute(@plan, total_without_coupon, @customer, coupon: @coupon.coupon, start_at: @start_at)
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
    if @plan&.disabled
      @errors[:item] = 'plan is disabled'
      return false
    end
    true
  end
end
