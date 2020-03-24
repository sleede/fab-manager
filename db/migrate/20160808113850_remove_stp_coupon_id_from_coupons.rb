# frozen_string_literal:true

class RemoveStpCouponIdFromCoupons < ActiveRecord::Migration[4.2]
  def change
    remove_column :coupons, :stp_coupon_id, :string
  end
end
