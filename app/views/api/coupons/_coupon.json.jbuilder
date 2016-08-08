json.extract! coupon, :id, :name, :code, :percent_off, :valid_until, :validity_per_user, :max_usages, :active, :created_at
json.usages coupon.invoices.count