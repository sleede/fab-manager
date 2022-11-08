class AddPaymentStateToOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :payment_state, :string
  end
end
