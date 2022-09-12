# frozen_string_literal: true

json.extract! order, :id, :token, :statistic_profile_id, :operator_profile_id, :reference, :state, :created_at, :updated_at, :invoice_id,
              :payment_method
json.total order.total / 100.0 if order.total.present?
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
  json.orderable_name item.orderable.name
  json.orderable_main_image_url item.orderable.main_image&.attachment_url
  json.quantity item.quantity
  json.amount item.amount / 100.0
  json.is_offered item.is_offered
end
