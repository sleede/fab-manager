# frozen_string_literal: true

# Provides methods for pay cart by Local
class Payments::LocalService
  include Payments::PaymentConcern

  def payment(order)
    o = payment_success(order)
    { order: o }
  end
end
