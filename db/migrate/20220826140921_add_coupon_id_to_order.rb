class AddCouponIdToOrder < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :coupon, index: true, foreign_key: true
  end
end
