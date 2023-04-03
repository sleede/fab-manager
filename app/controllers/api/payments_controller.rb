# frozen_string_literal: true

# Abstract API Controller to be extended by each payment gateway/mean, for handling the payments processes in the front-end
class API::PaymentsController < API::APIController
  before_action :authenticate_user!

  # This method must be overridden by the the gateways controllers that inherits API::PaymentsControllers
  def confirm_payment
    raise NoMethodError
  end

  protected

  def post_save(_gateway_item_id, _gateway_item_type, _payment_document); end

  def get_wallet_debit(user, total_amount)
    wallet_amount = (user.wallet.amount * 100).to_i
    wallet_amount >= total_amount ? total_amount : wallet_amount
  end

  def debit_amount(cart)
    price_details = cart.total

    # Subtract wallet amount from total
    total = price_details[:total]
    wallet_debit = get_wallet_debit(current_user, total)
    { amount: total - wallet_debit, details: price_details }
  end

  def shopping_cart
    cs = CartService.new(current_user)
    cs.from_hash(params[:cart_items])
  end

  def on_payment_success(gateway_item_id, gateway_item_type, cart)
    res = cart.build_and_save(gateway_item_id, gateway_item_type)
    if res[:success]
      post_save(gateway_item_id, gateway_item_type, res[:payment])
      res[:payment].render_resource.merge(status: :created)
    else
      { json: res[:errors].drop_while(&:empty?), status: :unprocessable_entity }
    end
  rescue StandardError => e
    Rails.logger.debug e.backtrace
    { json: e, status: :unprocessable_entity }
  end
end
