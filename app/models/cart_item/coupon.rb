# frozen_string_literal: true

# A discount coupon applied to the whole shopping cart
class CartItem::Coupon
  attr_reader :errors

  # @param coupon {String|Coupon} may be nil or empty string if no coupons are applied
  def initialize(customer, operator, coupon)
    @customer = customer
    @operator = operator
    @coupon = coupon
    @errors = {}
  end

  def coupon
    cs = CouponService.new
    cs.validate(@coupon, @customer.id)
  end

  def price(cart_total = 0)
    cs = CouponService.new
    new_total = cs.apply(cart_total, coupon)

    amount = new_total - cart_total

    { amount: amount, total_with_coupon: new_total, total_without_coupon: cart_total }
  end

  def type
    'coupon'
  end

  def valid?(_all_items)
    return true if @coupon.nil?

    c = ::Coupon.find_by(code: @coupon)
    if c.nil? || c.status(@customer.id) != 'active'
      @errors[:item] = 'coupon is invalid'
      return false
    end
    true
  end
end
