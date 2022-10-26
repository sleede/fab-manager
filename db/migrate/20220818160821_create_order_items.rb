# frozen_string_literal:true

# OrderItem for save article of Order
class CreateOrderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :order_items do |t|
      t.belongs_to :order, foreign_key: true
      t.references :orderable, polymorphic: true
      t.integer :amount
      t.integer :quantity
      t.boolean :is_offered

      t.timestamps
    end
  end
end
