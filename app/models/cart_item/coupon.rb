# frozen_string_literal: true

# A discount coupon applied to the whole shopping cart
class CartItem::Coupon < ApplicationRecord
  self.table_name = 'cart_item_coupons'

  belongs_to :operator_profile, class_name: 'InvoicingProfile'
  belongs_to :customer_profile, class_name: 'InvoicingProfile'
  belongs_to :coupon

  def operator
    operator_profile.user
  end

  def customer
    customer_profile.user
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
    return true if coupon.nil?

    if coupon.status(customer.id) != 'active'
      errors.add(:coupon, 'invalid coupon')
      return false
    end
    true
  end
end
