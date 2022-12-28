# frozen_string_literal: true

# Coupon's codes should validate uniqness in database
class AddUniqueIndexOnCouponCode < ActiveRecord::Migration[5.2]
  def change
    add_index :coupons, :code, unique: true
  end
end
