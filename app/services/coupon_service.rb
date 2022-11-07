# frozen_string_literal: true

# This class provides helper methods to deal with coupons
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
  def apply(total, coupon = nil, user_id = nil)
    price = total

    coupon_object = if coupon.instance_of? Coupon
                      coupon
                    elsif coupon.instance_of? String
                      Coupon.find_by(code: coupon)
                    else
                      nil
                    end

    return price if coupon_object.nil?

    if coupon_object.status(user_id, total) == 'active'
      case coupon_object.type
      when 'percent_off'
        price -= (Rational(price * coupon_object.percent_off) / Rational(100.0)).to_f.ceil
      when 'amount_off'
        # do not apply cash coupon unless it has a lower amount that the total price
        price -= coupon_object.amount_off if coupon_object.amount_off <= price
      else
        raise InvalidCouponError("unsupported coupon type #{coupon_object.type}")
      end
    end

    price
  end

  # Apply the provided coupon to the given amount, considering that this applies to a refund invoice (Avoir),
  # potentially partial
  def self.apply_on_refund(amount, coupon, paid_items = 1, refund_items = 1)
    return amount if coupon.nil?

    case coupon.type
    when 'percent_off'
      amount - (Rational(amount * coupon.percent_off) / Rational(100.0)).to_f.ceil
    when 'amount_off'
      amount - (Rational(coupon.amount_off / paid_items) * Rational(refund_items)).to_f.ceil
    else
      raise InvalidCouponError
    end
  end

  ##
  # Find the coupon associated with the given code and check it is valid for the given user
  # @param code {String} the literal code of the coupon
  # @param user_id {Number} identifier of the user who is applying the coupon
  # @return {Coupon}
  ##
  def validate(code, user_id)
    return nil unless code && user_id

    coupon = Coupon.find_by(code: code)
    raise InvalidCouponError if coupon.nil? || coupon.status(user_id) != 'active'

    coupon
  end

  ##
  # Ventilate the discount of the provided coupon over the given amount proportionately to the invoice's total
  # @param total {Number} total amount of the invoice expressed in centimes
  # @param amount {Number} price of the invoice's sub-item expressed in centimes
  # @param coupon {Coupon} coupon applied to the invoice, amount_off expressed in centimes if applicable
  ##
  def ventilate(total, amount, coupon)
    price = amount
    if !coupon.nil? && total != 0
      case coupon.type
      when 'percent_off'
        price = amount - (Rational(amount * coupon.percent_off) / Rational(100.00)).to_f.round
      when 'amount_off'
        ratio = Rational(amount) / Rational(total)
        discount = (coupon.amount_off * ratio.abs)
        price = (amount - discount).to_f.round
      else
        raise InvalidCouponError("unsupported coupon type #{coupon.type}")
      end
    end
    price
  end

  ##
  # Compute the total amount of the given invoice, without the applied coupon
  # Invoice.total stores the amount payed by the customer, coupon deducted
  # @param invoice {Invoice} invoice object, its total before discount will be computed
  # @return {Number} total in centimes
  ##
  def invoice_total_no_coupon(invoice)
    invoice.invoice_items.map(&:amount).map(&:to_i).reduce(:+) or 0
  end
end
