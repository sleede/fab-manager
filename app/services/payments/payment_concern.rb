# frozen_string_literal: true

# Concern for Payment
module Payments::PaymentConcern
  private

  def get_wallet_debit(user, total_amount)
    wallet_amount = (user.wallet.amount * 100).to_i
    wallet_amount >= total_amount ? total_amount : wallet_amount
  end

  def debit_amount(order, coupon_code = nil)
    total = CouponService.new.apply(order.total, coupon_code, order.statistic_profile.user.id)
    wallet_debit = get_wallet_debit(order.statistic_profile.user, total)
    total - wallet_debit
  end

  def payment_success(order, coupon_code, payment_method = '', payment_id = nil, payment_type = nil)
    ActiveRecord::Base.transaction do
      order.paid_total = debit_amount(order, coupon_code)
      coupon = Coupon.find_by(code: coupon_code)
      order.coupon_id = coupon.id if coupon
      WalletService.debit_user_wallet(order, order.statistic_profile.user)
      order.operator_profile_id = order.statistic_profile.user.invoicing_profile.id if order.operator_profile.nil?
      order.payment_method = if order.total == order.wallet_amount
                               'wallet'
                             else
                               payment_method
                             end
      order.state = 'in_progress'
      order.payment_state = 'paid'
      if payment_id && payment_type
        order.payment_gateway_object = PaymentGatewayObject.new(gateway_object_id: payment_id, gateway_object_type: payment_type)
      end
      order.order_items.each do |item|
        ProductService.update_stock(item.orderable,
                                    [{ stock_type: 'external', reason: 'sold', quantity: item.quantity, order_item_id: item.id }]).save
      end
      create_invoice(order, coupon, payment_id, payment_type) if order.save
      order.reload
    end
  end

  def create_invoice(order, coupon, payment_id, payment_type)
    invoice = InvoicesService.create(
      { total: order.total, coupon: coupon },
      order.operator_profile_id,
      order.order_items,
      order.statistic_profile.user,
      payment_id: payment_id,
      payment_type: payment_type,
      payment_method: order.payment_method
    )
    invoice.wallet_amount = order.wallet_amount
    invoice.wallet_transaction_id = order.wallet_transaction_id
    invoice.save
    order.update(invoice_id: invoice.id)
  end
end
