json.price @amount[:total] / 100.00
json.price_without_coupon @amount[:before_coupon] / 100.00
json.details do
  json.slots @amount[:elements][:slots] do |slot|
    json.start_at slot[:start_at]
    json.price slot[:price] / 100.00
    json.promo slot[:promo]
  end
  json.plan @amount[:elements][:plan] / 100.00 if @amount[:elements][:plan]
end if @amount[:elements]
