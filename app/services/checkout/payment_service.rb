# frozen_string_literal: true

# Provides methods for pay cart
class Checkout::PaymentService
  require 'pay_zen/helper'
  require 'stripe/helper'
  include Payments::PaymentConcern

  def payment(order, operator, payment_id = '')
    raise Cart::OutStockError unless Orders::OrderService.new.in_stock?(order, 'external')

    raise Cart::InactiveProductError unless Orders::OrderService.new.all_products_is_active?(order)

    amount = debit_amount(order)
    if operator.privileged? || amount.zero?
      Payments::LocalService.new.payment(order)
    elsif operator.member?
      if Stripe::Helper.enabled?
        Payments::StripeService.new.payment(order, payment_id)
      elsif PayZen::Helper.enabled?
        Payments::PayzenService.new.payment(order)
      else
        raise Error('Bad gateway or online payment is disabled')
      end
    end
  end

  def confirm_payment(order, operator, payment_id = '')
    if operator.member?
      if Stripe::Helper.enabled?
        Payments::StripeService.new.confirm_payment(order, payment_id)
      elsif PayZen::Helper.enabled?
        Payments::PayzenService.new.confirm_payment(order, payment_id)
      else
        raise Error('Bad gateway or online payment is disabled')
      end
    end
  end
end
