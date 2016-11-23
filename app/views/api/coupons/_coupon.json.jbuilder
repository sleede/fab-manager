json.extract! coupon, :id, :name, :code, :type, :percent_off, :valid_until, :validity_per_user, :max_usages, :active, :created_at
json.amount_off (coupon.amount_off / 100.00) unless coupon.amount_off.nil?
json.usages coupon.invoices.count
json.status coupon.status