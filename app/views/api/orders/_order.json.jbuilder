# frozen_string_literal: true

json.extract! order, :id, :token, :statistic_profile_id, :operator_profile_id, :reference, :state, :created_at, :updated_at, :invoice_id,
              :payment_method
json.total order.total / 100.0 if order.total.present?
json.payment_date order.invoice.created_at if order.invoice_id.present?
json.wallet_amount order.wallet_amount / 100.0 if order.wallet_amount.present?
json.paid_total order.paid_total / 100.0 if order.paid_total.present?
if order.coupon_id
  json.coupon do
    json.extract! order.coupon, :id, :code, :type, :percent_off, :validity_per_user
    json.amount_off order.coupon.amount_off / 100.00 unless order.coupon.amount_off.nil?
  end
end
if order&.statistic_profile&.user
  json.user do
    json.id order.statistic_profile.user.id
    json.role order.statistic_profile.user.roles.first.name
    json.name order.statistic_profile.user.profile.full_name
  end
end

json.order_items_attributes order.order_items.order(created_at: :asc) do |item|
  json.id item.id
  json.orderable_type item.orderable_type
  json.orderable_id item.orderable_id
  json.quantity item.quantity
  json.amount item.amount / 100.0
  json.is_offered item.is_offered
  json.partial! 'api/orders/product', item: item if item.orderable_type == 'Product'
  if %w[CartItem::MachineReservation CartItem::SpaceReservation CartItem::TrainingReservation].include?(item.orderable_type)
    json.partial! 'api/orders/cart_item_reservation', item: item
  end
end
