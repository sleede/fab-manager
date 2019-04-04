# frozen_string_literal: true

json.array!(@coupons) do |coupon|
  json.partial! 'api/coupons/coupon', coupon: coupon
  json.total @total
end
