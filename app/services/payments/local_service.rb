# frozen_string_literal: true

# Provides methods for pay cart by Local
class Payments::LocalService
  include Payments::PaymentConcern

  def payment(order, coupon_code)
    o = payment_success(order, coupon_code, 'local')
    { order: o }
  end
end
