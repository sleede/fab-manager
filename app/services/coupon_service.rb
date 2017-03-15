class CouponService
  ##
  # Apply the provided coupon, if active, to the given price. Usability tests will be run depending on the
  # provided parameters.
  # If no coupon/coupon code or if the code does not match, return origin price without change
  #
  # @param total {Number} invoice total, before any coupon is applied
  # @param coupon {String|Coupon} Coupon's code OR Coupon object
  # @param user_id {Number} user's id against the coupon will be tested for usability
  # @return {Number}
  ##
  def apply(total, coupon, user_id = nil)
    price = total

    _coupon = nil
    if coupon.instance_of? Coupon
      _coupon = coupon
    elsif coupon.instance_of? String
      _coupon = Coupon.find_by(code: coupon)
    end

    unless _coupon.nil?
      if _coupon.status(user_id, total) == 'active'
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


  ##
  # Ventilate the discount of the provided coupon over the given amount proportionately to the invoice's total
  # @param total {Number} total amount of the invoice expressed in monetary units
  # @param amount {Number} price of the invoice's sub-item expressed in monetary units
  # @param coupon {Coupon} coupon applied to the invoice, amount_off expressed in centimes if applicable
  ##
  def ventilate(total, amount, coupon)
    price = amount
    if !coupon.nil? and total != 0
      if coupon.type == 'percent_off'
        price = amount - ( amount * coupon.percent_off / 100.0 )
      elsif coupon.type == 'amount_off'
        ratio = (coupon.amount_off / 100.0) / total
        discount = amount * ratio.abs
        price = amount - discount
      else
        raise InvalidCouponError
      end
    end
    price
  end
end