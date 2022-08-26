class AddOrderItemIdToProductStockMovement < ActiveRecord::Migration[5.2]
  def change
    add_column :product_stock_movements, :order_item_id, :integer
  end
end
