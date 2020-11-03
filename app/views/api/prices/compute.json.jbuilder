json.price @amount[:total] / 100.00
json.price_without_coupon @amount[:before_coupon] / 100.00
if @amount[:elements]
  json.details do
    json.slots @amount[:elements][:slots] do |slot|
      json.start_at slot[:start_at]
      json.price slot[:price] / 100.00
      json.promo slot[:promo]
    end
    json.plan @amount[:elements][:plan] / 100.00 if @amount[:elements][:plan]
  end
end
if @amount[:schedule]
  json.schedule do
    json.items @amount[:schedule][:items] do |item|
      json.price item.amount / 100.00
      json.due_date item.due_date
    end
  end
end
