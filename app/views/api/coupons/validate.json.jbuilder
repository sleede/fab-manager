# frozen_string_literal: true

json.extract! @coupon, :id, :code, :type, :percent_off, :validity_per_user
json.amount_off (@coupon.amount_off / 100.00) unless @coupon.amount_off.nil?
