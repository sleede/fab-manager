class RemovePaymentStateFromOrders < ActiveRecord::Migration[5.2]
  def change
    remove_column :orders, :payment_state
  end
end
