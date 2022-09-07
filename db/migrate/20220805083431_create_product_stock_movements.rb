# frozen_string_literal: true

class CreateProductStockMovements < ActiveRecord::Migration[5.2]
  def change
    create_table :product_stock_movements do |t|
      t.belongs_to :product, foreign_key: true
      t.integer :quantity
      t.string :reason
      t.string :stock_type
      t.integer :remaining_stock
      t.datetime :date

      t.timestamps
    end
  end
end
