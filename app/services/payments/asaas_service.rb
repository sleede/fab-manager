# frozen_string_literal: true

require 'securerandom'
require 'asaas/client'
require 'asaas/helper'
require 'asaas/service'

# Provides methods for pay cart or orders by Asaas Pix
class Payments::AsaasService
  include Payments::PaymentConcern

  MINIMUM_PIX_AMOUNT = 500

  def create_cart_payment(cart, operator, document)
    raise PaymentGatewayError, 'Payment schedules are not supported with Asaas Pix' if cart.payment_schedule&.requested

    amount = debit_amount_from_cart(cart)
    raise Cart::ZeroPriceError if amount.zero?

    validate_minimum_amount!(amount)

    create_payment(customer: cart.customer, operator: operator, cart_items: cart_to_h(cart), source: nil, document: document) do |payment|
      description = cart.items.map(&:name).join(', ')
      [amount, description.presence || 'Fab-manager Pix payment', payment]
    end
  end

  def create_order_payment(order, operator, coupon_code, document)
    raise Cart::InactiveProductError unless Orders::OrderService.all_products_is_active?(order)
    raise Cart::OutStockError unless Orders::OrderService.in_stock?(order, 'external')
    raise Cart::QuantityMinError unless Orders::OrderService.greater_than_quantity_min?(order)
    raise Cart::ItemAmountError unless Orders::OrderService.item_amount_not_equal?(order)

    CouponService.new.validate(coupon_code, order.statistic_profile.user.id)

    amount = debit_amount(order, coupon_code)
    raise Cart::ZeroPriceError if amount.zero?

    validate_minimum_amount!(amount)

    create_payment(customer: order.statistic_profile.user, operator: operator, source: order, document: document) do |payment|
      [amount, Asaas::Helper.payment_description(order), payment]
    end
  end

  def payment_status(token)
    AsaasPayment.find_by!(token: token)
  end

  def refresh_status(payment)
    return payment if payment.paid? || payment.failed? || payment.expired?
    return payment if payment.asaas_payment_id.blank?

    asaas_payment = client.get("/v3/payments/#{payment.asaas_payment_id}")
    payment.update!(payment_data: asaas_payment)
    finalize!(payment, asaas_payment, nil) if asaas_payment['status'] == 'RECEIVED'
    expire!(payment, asaas_payment) if %w[OVERDUE DELETED].include?(asaas_payment['status'])
    payment.reload
  end

  def handle_webhook(event_name, payment_payload)
    payload = payment_payload.to_h
    payment = AsaasPayment.find_by!(asaas_payment_id: payload['id'])
    finalize!(payment, payload, event_name)
  end

  private

  def create_payment(customer:, operator:, cart_items: nil, source: nil, document: nil)
    validate_document!(document)

    remote_customer = ensure_customer(customer, document)
    payment = build_payment(customer, operator, cart_items, source, remote_customer)

    amount, description, current_payment = yield(payment)
    current_payment.update!(amount: amount)

    remote_payment = create_remote_payment(remote_customer, amount, description, current_payment.token, document)
    update_payment_with_qr_code!(current_payment, remote_payment)
    current_payment
  rescue StandardError => e
    payment&.update(status: 'failed') if payment&.persisted? && !payment.paid?
    Rails.logger.error("[AsaasPayment] #{e.class}: #{e.message}")
    raise
  end

  def build_payment(customer, operator, cart_items, source, remote_customer)
    AsaasPayment.create!(
      token: SecureRandom.hex(16),
      status: 'pending',
      customer: customer,
      operator: operator,
      item: source,
      cart_items: cart_items,
      asaas_customer_id: remote_customer.gateway_object_id
    )
  end

  def create_remote_payment(remote_customer, amount, description, token, document)
    client.post('/v3/payments', {
                  customer: remote_customer.gateway_object_id,
                  billingType: 'PIX',
                  cpfCnpj: normalize_document(document),
                  value: amount / 100.0,
                  dueDate: Asaas::Helper.due_date,
                  description: description,
                  externalReference: token
                })
  end

  def update_payment_with_qr_code!(payment, remote_payment)
    qr_code = client.get("/v3/payments/#{remote_payment['id']}/pixQrCode")

    payment.update!(
      status: 'waiting_payment',
      asaas_payment_id: remote_payment['id'],
      payment_data: remote_payment,
      pix_payload: qr_code['payload'],
      pix_encoded_image: qr_code['encodedImage'],
      pix_expiration_at: qr_code['expirationDate']
    )
  end

  def ensure_customer(user, document)
    pgo = user.payment_gateway_object
    if pgo&.gateway_object_type == 'Asaas::Customer'
      remote_customer = client.get("/v3/customers/#{pgo.gateway_object_id}")
      return pgo if remote_customer['cpfCnpj'].present?

      Asaas::Service.new.update_user(user.id, document)
      return pgo
    end

    Asaas::Service.new.create_user(user.id, document)
    user.reload.payment_gateway_object
  end

  def validate_document!(document)
    raise AsaasError, 'CPF is required to generate the Pix payment' if document.blank?
    raise AsaasError, 'Invalid CPF' unless valid_cpf?(document)
  end

  def validate_minimum_amount!(amount)
    return if amount >= MINIMUM_PIX_AMOUNT

    raise AsaasError, 'Asaas Pix only supports payments from R$ 5,00.'
  end

  def normalize_document(document) = document.to_s.gsub(/\D/, '')

  def valid_cpf?(document)
    cpf = normalize_document(document)
    return false unless cpf.match?(/\A\d{11}\z/)
    return false if cpf.chars.uniq.one?

    digits = cpf.chars.map(&:to_i)
    verifier = lambda do |base, factor|
      sum = base.each_with_index.sum { |digit, index| digit * (factor - index) }
      mod = (sum * 10) % 11
      mod == 10 ? 0 : mod
    end

    digits[9] == verifier.call(digits[0...9], 10) && digits[10] == verifier.call(digits[0...10], 11)
  end

  def finalize!(payment, payment_payload, event_name)
    return payment if payment.paid?
    return expire!(payment, payment_payload, event_name) if %w[PAYMENT_OVERDUE PAYMENT_DELETED].include?(event_name) ||
                                                            %w[OVERDUE DELETED].include?(payment_payload['status'])
    return payment unless event_name.in?([nil, 'PAYMENT_RECEIVED', 'PAYMENT_CONFIRMED']) || payment_payload['status'] == 'RECEIVED'

    result = nil

    ActiveRecord::Base.transaction do
      result = if payment.item.is_a?(Order)
                 payment_success(
                   payment.item,
                   payment.item.coupon&.code,
                   Asaas::Helper.payment_method,
                   payment.asaas_payment_id,
                   'Asaas::Payment'
                 )
               else
                 cart = CartService.new(payment.operator).from_hash(payment.cart_items)
                 res = cart.build_and_save(payment.asaas_payment_id, 'Asaas::Payment')
                 raise AsaasError, Array(res[:errors]).join(', ') unless res[:success]

                 res[:payment]
               end

      payment.update!(
        status: 'paid',
        event_name: event_name,
        payment_data: payment_payload,
        paid_at: Time.current,
        finalized_at: Time.current,
        result: result
      )
    end

    payment.reload
  end

  def expire!(payment, payment_payload, event_name = nil)
    return payment if payment.paid?

    payment.update!(status: 'expired', event_name: event_name, payment_data: payment_payload)
    payment
  end

  def debit_amount_from_cart(cart)
    total = cart.total[:total]
    wallet_amount = get_wallet_debit(cart.customer, total)
    total - wallet_amount
  end

  def cart_to_h(cart)
    {
      customer_id: cart.customer.id,
      items: cart.items.map { |item| serialize_item(item) },
      coupon_code: cart.coupon.coupon&.code,
      payment_schedule: false,
      payment_method: Asaas::Helper.payment_method
    }
  end

  def serialize_item(item)
    case item
    when CartItem::Subscription
      { subscription: { plan_id: item.plan_id, start_at: item.start_at } }
    when CartItem::PrepaidPack
      { prepaid_pack: { id: item.prepaid_pack_id } }
    when CartItem::FreeExtension
      { free_extension: { end_at: item.new_expiration_date } }
    when CartItem::Reservation
      {
        reservation: {
          reservable_id: item.reservable_id,
          reservable_type: item.reservable_type,
          reservation_context_id: item.reservation_context_id,
          slots_reservations_attributes: item.cart_item_reservation_slots.map { |slot| { slot_id: slot.slot_id, offered: slot.offered } },
          nb_reserve_places: item.try(:normal_tickets),
          tickets_attributes: item.try(:cart_item_event_reservation_tickets)&.map do |ticket|
            { event_price_category_id: ticket.event_price_category_id, booked: ticket.booked }
          end,
          booking_users_attributes: item.try(:cart_item_event_reservation_booking_users)&.map do |booking_user|
            {
              name: booking_user.try(:name),
              booked_type: booking_user.booked_type,
              booked_id: booking_user.booked_id,
              event_price_category_id: booking_user.event_price_category_id
            }
          end
        }.compact
      }
    else
      raise NotImplementedError, "Unsupported cart item for Asaas serialization: #{item.class.name}"
    end
  end

  def client = @client ||= Asaas::Client.new
end
