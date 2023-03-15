# frozen_string_literal: true

# API Controller for handling local payments (at the reception) or when the amount = 0
class API::LocalPaymentController < API::PaymentsController
  def confirm_payment
    cart = shopping_cart
    price = debit_amount(cart)

    authorize LocalPaymentContext.new(cart, price[:amount])

    render json: cart.errors, status: :unprocessable_entity and return unless cart.valid?

    render on_payment_success(nil, nil, cart)
  end

  protected

  def shopping_cart
    cs = CartService.new(current_user)
    cs.from_hash(params)
  end
end
