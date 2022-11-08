# frozen_string_literal: true

class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|
      t.string :name
      t.string :slug
      t.string :sku
      t.text :description
      t.boolean :is_active, default: false
      t.belongs_to :product_category, foreign_key: true
      t.integer :amount
      t.integer :quantity_min
      t.jsonb :stock, default: { internal: 0, external: 0 }
      t.boolean :low_stock_alert, default: false
      t.integer :low_stock_threshold

      t.timestamps
    end
  end
end
