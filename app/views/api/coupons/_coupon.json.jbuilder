json.extract! coupon, :id, :name, :code, :type, :percent_off, :amount_off, :valid_until, :validity_per_user, :max_usages, :active, :created_at
json.usages coupon.invoices.count
json.status coupon.status