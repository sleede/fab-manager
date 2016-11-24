json.extract! @coupon, :id, :code, :type, :percent_off
json.amount_off (@coupon.amount_off / 100.00) unless @coupon.amount_off.nil?