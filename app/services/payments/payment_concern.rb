# frozen_string_literal: true

# Concern for Payment
module Payments::PaymentConcern
  private

  def get_wallet_debit(user, total_amount)
    wallet_amount = (user.wallet.amount * 100).to_i
    wallet_amount >= total_amount ? total_amount : wallet_amount
  end

  def debit_amount(order)
    total = order.total
    wallet_debit = get_wallet_debit(order.statistic_profile.user, total)
    total - wallet_debit
  end

  def payment_success(order)
    ActiveRecord::Base.transaction do
      WalletService.debit_user_wallet(order, order.statistic_profile.user)
      order.update(state: 'in_progress', payment_state: 'paid')
      order.order_items.each do |item|
        ProductService.update_stock(item.orderable, 'external', 'sold', -item.quantity)
      end
      order.reload
    end
  end
end
