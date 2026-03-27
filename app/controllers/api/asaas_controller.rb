# frozen_string_literal: true

require 'asaas/helper'

# API controller for handling Asaas Pix payments
class API::AsaasController < API::APIController
  protect_from_forgery except: :webhook

  before_action :authenticate_user!, except: :webhook

  def create_payment
    render(json: { error: 'Bad gateway or online payment is disabled' }, status: :bad_gateway) and return unless Asaas::Helper.enabled?

    payment = if params[:order_token].present?
                order = Order.find_by!(token: params[:order_token])
                Payments::AsaasService.new.create_order_payment(order, current_user, params[:coupon_code], params[:cpf])
              else
                cart = shopping_cart
                render json: cart.errors, status: :unprocessable_entity and return unless cart.valid?

                Payments::AsaasService.new.create_cart_payment(cart, current_user, params[:cpf])
              end

    render json: payment_response(payment)
  rescue StandardError => e
    render json: { error: Asaas::Helper.human_error(e) }, status: :unprocessable_entity
  end

  def status
    payment = Payments::AsaasService.new.payment_status(params[:token])
    payment = Payments::AsaasService.new.refresh_status(payment)

    if payment.paid? && payment.result
      render_result(payment.result)
    elsif payment.expired?
      render json: { status: 'expired' }, status: :ok
    else
      render json: payment_response(payment), status: :ok
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'not_found' }, status: :not_found
  end

  def webhook
    Payments::AsaasService.new.handle_webhook(params[:event], params[:payment]&.to_unsafe_h || {})
    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue StandardError => e
    Rails.logger.error("[AsaasWebhook] #{e.class}: #{e.message}")
    head :unprocessable_entity
  end

  private

  def payment_response(payment)
    {
      token: payment.token,
      status: payment.status,
      pix_payload: payment.pix_payload,
      pix_encoded_image: payment.pix_encoded_image,
      pix_expiration_at: payment.pix_expiration_at
    }
  end

  def shopping_cart
    cs = CartService.new(current_user)
    cs.from_hash(params[:cart_items])
  end

  def render_result(result)
    case result
    when Order
      @order = result
      render 'api/orders/show', status: :ok
    else
      render result.render_resource.merge(status: :ok)
    end
  end
end
