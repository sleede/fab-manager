class AddValidityPerUserToCoupon < ActiveRecord::Migration
  def change
    add_column :coupons, :validity_per_user, :string
  end
end
