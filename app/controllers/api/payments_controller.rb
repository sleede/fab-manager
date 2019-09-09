# frozen_string_literal: true

# API Controller for handling payments process in the front-end
class API::PaymentsController < API::ApiController
  before_action :authenticate_user!

  def confirm_payment

    begin
      if params[:payment_method_id].present?
        # Create the PaymentIntent
        # TODO the client has to provide the reservation details. Then, we use Price.compute - user.walletAmount to get the amount
        # currency is set in Rails.secrets
        
        reservable = cart_items_params[:reservable_type].constantize.find(cart_items_params[:reservable_id])
        price_details = Price.compute(false,
                              current_user,
                              reservable,
                              cart_items_params[:slots_attributes] || [],
                              cart_items_params[:plan_id],
                              cart_items_params[:nb_reserve_places],
                              cart_items_params[:tickets_attributes],
                              coupon_params[:coupon_code])

        intent = Stripe::PaymentIntent.create(
          payment_method: params[:payment_method_id],
          amount: price_details[:total],
          currency: 'eur', 
          confirmation_method: 'manual',
          confirm: true
        )
      elsif params[:payment_intent_id].present?
        intent = Stripe::PaymentIntent.confirm(params[:payment_intent_id])

          
      end
    rescue Stripe::CardError => e
      # Display error on client
      render status: 200, json: { error: e.message }
    end

    if intent.status == 'succeeded' 
      begin
        user_id = params[:cart_items][:reservation][:user_id] 

        @reservation = Reservation.new(reservation_params)
        is_reserve = Reservations::Reserve.new(user_id, current_user.invoicing_profile.id)
                                          .pay_and_save(@reservation, :stripe, coupon_params[:coupon_code])
    
        if is_reserve
          SubscriptionExtensionAfterReservation.new(@reservation).extend_subscription_if_eligible
    
          render('api/reservations/show', status: :created, location: @reservation) and return
        else
          render(json: @reservation.errors, status: :unprocessable_entity) and return
        end
      rescue InvalidCouponError
        render(json: { coupon_code: 'wrong coupon code or expired' }, status: :unprocessable_entity) and return
      end
    end

    render generate_payment_response(intent)
  end

  private

  def generate_payment_response(intent)
    if intent.status == 'requires_action' && intent.next_action.type == 'use_stripe_sdk'
      # Tell the client to handle the action
      {
        status: 200,
        json: {
          requires_action: true,
          payment_intent_client_secret: intent.client_secret
        }
      }
    elsif intent.status == 'succeeded'
      # The payment didn’t need any additional actions and is completed!
      # Handle post-payment fulfillment
      { status: 200, json: { success: true } }
    else
      # Invalid status
      { status: 500, json: { error: 'Invalid PaymentIntent status' } }
    end
  end

  def reservation_params
    params[:cart_items].require(:reservation).permit(:reservable_id, :reservable_type, :plan_id, :nb_reserve_places,
                                        tickets_attributes: %i[event_price_category_id booked],
                                        slots_attributes: %i[id start_at end_at availability_id offered])
  end
  
  def cart_items_params
    params[:cart_items].require(:reservation).permit(:reservable_id, :reservable_type, :plan_id, :user_id, :nb_reserve_places,
                                        tickets_attributes: %i[event_price_category_id booked],
                                        slots_attributes: %i[id start_at end_at availability_id offered])
  end

  def coupon_params
    params.require(:cart_items).permit(:coupon_code)
  end
end