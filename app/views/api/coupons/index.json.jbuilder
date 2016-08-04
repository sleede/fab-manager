json.cache! [@coupons] do
  json.array!(@coupons) do |coupon|
    json.partial! 'api/coupons/coupon', coupon: coupon
  end
end
