# frozen_string_literal: true

# Provides methods for pay cart
class Checkout::PaymentService
  require 'pay_zen/helper'
  require 'stripe/helper'

  def payment(order, operator, payment_id = '')
    if operator.member?
      if Stripe::Helper.enabled?
        Payments::StripeService.new.payment(order, payment_id)
      elsif PayZen::Helper.enabled?
        Payments::PayzenService.new.payment(order)
      else
        raise Error('Bad gateway or online payment is disabled')
      end
    elsif operator.privileged?
      Payments::LocalService.new.payment(order)
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
