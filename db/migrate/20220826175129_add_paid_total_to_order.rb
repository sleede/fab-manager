class AddPaidTotalToOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :paid_total, :integer
  end
end
