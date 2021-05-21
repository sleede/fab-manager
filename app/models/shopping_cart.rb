# frozen_string_literal: true

# Stores data about a shopping data
class ShoppingCart
  attr_accessor :customer, :operator, :payment_method, :items, :coupon, :payment_schedule

  # @param items {Array<CartItem::BaseItem>}
  # @param coupon {CartItem::Coupon}
  # @param payment_schedule {CartItem::PaymentSchedule}
  # @param customer {User}
  # @param operator {User}
  def initialize(customer, operator, coupon, payment_schedule, payment_method = '', items: [])
    raise TypeError unless customer.is_a? User

    @customer = customer
    @operator = operator
    @payment_method = payment_method
    @items = items
    @coupon = coupon
    @payment_schedule = payment_schedule
  end

  def subscription
    @items.find { |item| item.is_a? CartItem::Subscription }
  end

  def reservation
    @items.find { |item| item.is_a? CartItem::Reservation }
  end

  # compute the price details of the current shopping cart
  def total
    total_amount = 0
    all_elements = { slots: [] }

    @items.map(&:price).each do |price|
      total_amount += price[:amount]
      all_elements = all_elements.merge(price[:elements]) do |_key, old_val, new_val|
        old_val | new_val
      end
    end

    coupon_info = @coupon.price(total_amount)
    schedule_info = @payment_schedule.schedule(coupon_info[:total_with_coupon], coupon_info[:total_without_coupon])

    # return result
    {
      elements: all_elements,
      total: schedule_info[:total].to_i,
      before_coupon: coupon_info[:total_without_coupon].to_i,
      coupon: @coupon.coupon,
      schedule: schedule_info[:schedule]
    }
  end

  def pay_and_save(payment_id, payment_type)
    price = total
    objects = []
    ActiveRecord::Base.transaction do
      items.each do |item|
        object = item.to_object
        object.save
        objects.push(object)
        raise ActiveRecord::Rollback unless object.errors.count.zero?
      end

      payment = if price[:schedule]
                  PaymentScheduleService.new.create(
                    subscription&.to_object,
                    price[:before_coupon],
                    coupon: @coupon,
                    operator: @operator,
                    payment_method: @payment_method,
                    user: @customer,
                    reservation: reservation&.to_object,
                    payment_id: payment_id,
                    payment_type: payment_type
                  )
                else
                  InvoicesService.create(
                    price,
                    @operator.invoicing_profile.id,
                    reservation: reservation&.to_object,
                    payment_id: payment_id,
                    payment_type: payment_type,
                    payment_method: @payment_method
                  )
                end
      payment.save
      payment.post_save(payment_id)
    end

    objects.map(&:errors).flatten.count.zero?
  end
end
