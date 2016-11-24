class CouponApplyService
  def call(total, coupon_code, user_id = nil)
    price = total

    # if no coupon code or if code does not match, return origin price without change
    unless coupon_code.nil?
      _coupon = Coupon.find_by(code: coupon_code)
      if not _coupon.nil? and _coupon.status(user_id) == 'active'
        if _coupon.type == 'percent_off'
          price = price - (price * _coupon.percent_off / 100.0)
        elsif _coupon.type == 'amount_off'
          # do not apply cash coupon unless it has a lower amount that the total price
          if _coupon.amount_off <= price
            price -= _coupon.amount_off
          end
        end
      end
    end

    price
  end
end