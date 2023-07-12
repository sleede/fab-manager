# frozen_string_literal: true

# Provides methods to pay the cart
class Checkout::PaymentService
  require 'pay_zen/helper'
  require 'stripe/helper'
  include Payments::PaymentConcern

  def payment(order, operator, coupon_code, payment_id = '')
    raise Cart::InactiveProductError unless Orders::OrderService.all_products_is_active?(order)

    raise Cart::OutStockError unless Orders::OrderService.in_stock?(order, 'external')

    raise Cart::QuantityMinError unless Orders::OrderService.greater_than_quantity_min?(order)

    raise Cart::ItemAmountError unless Orders::OrderService.item_amount_not_equal?(order)

    CouponService.new.validate(coupon_code, order.statistic_profile.user.id)

    amount = debit_amount(order, coupon_code)
    if (operator.privileged? && operator != order.statistic_profile.user) || amount.zero?
      Payments::LocalService.new.payment(order, coupon_code)
    elsif Stripe::Helper.enabled? && payment_id.present?
      Payments::StripeService.new.payment(order, coupon_code, payment_id)
    elsif PayZen::Helper.enabled?
      Payments::PayzenService.new.payment(order, coupon_code)
    else
      raise PaymentGatewayError, 'Bad gateway or online payment is disabled'
    end
  end

  def confirm_payment(order, coupon_code, payment_id = '')
    if Stripe::Helper.enabled?
      Payments::StripeService.new.confirm_payment(order, coupon_code, payment_id)
    elsif PayZen::Helper.enabled?
      Payments::PayzenService.new.confirm_payment(order, coupon_code, payment_id)
    else
      raise PaymentGatewayError, 'Bad gateway or online payment is disabled'
    end
  end
end
