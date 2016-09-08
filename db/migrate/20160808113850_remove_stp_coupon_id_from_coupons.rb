class RemoveStpCouponIdFromCoupons < ActiveRecord::Migration
  def change
    remove_column :coupons, :stp_coupon_id, :string
  end
end
