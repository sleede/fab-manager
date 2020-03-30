# frozen_string_literal:true

class AddAmountOffToCoupons < ActiveRecord::Migration[4.2]
  def change
    add_column :coupons, :amount_off, :integer
  end
end
