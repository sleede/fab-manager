# frozen_string_literal: true

# Provides methods for pay cart
class Checkout::PaymentService
  require 'pay_zen/helper'
  require 'stripe/helper'
  include Payments::PaymentConcern

  def payment(order, operator, coupon_code, payment_id = '')
    raise Cart::InactiveProductError unless Orders::OrderService.new.all_products_is_active?(order)

    raise Cart::OutStockError unless Orders::OrderService.new.in_stock?(order, 'external')

    CouponService.new.validate(coupon_code, order.statistic_profile.user.id)

    amount = debit_amount(order)
    if operator.privileged? || amount.zero?
      Payments::LocalService.new.payment(order, coupon_code)
    elsif operator.member?
      if Stripe::Helper.enabled?
        Payments::StripeService.new.payment(order, coupon_code, payment_id)
      elsif PayZen::Helper.enabled?
        Payments::PayzenService.new.payment(order, coupon_code)
      else
        raise Error('Bad gateway or online payment is disabled')
      end
    end
  end

  def confirm_payment(order, operator, coupon_code, payment_id = '')
    return unless operator.member?

    if Stripe::Helper.enabled?
      Payments::StripeService.new.confirm_payment(order, coupon_code, payment_id)
    elsif PayZen::Helper.enabled?
      Payments::PayzenService.new.confirm_payment(order, coupon_code, payment_id)
    else
      raise Error('Bad gateway or online payment is disabled')
    end
  end
end
