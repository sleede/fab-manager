# frozen_string_literal:true

class CouponUsage < ApplicationRecord
  belongs_to :coupon
  belongs_to :object, polymorphic: true
end
