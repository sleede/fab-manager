class AddAmountOffToCoupons < ActiveRecord::Migration
  def change
    add_column :coupons, :amount_off, :integer
  end
end
