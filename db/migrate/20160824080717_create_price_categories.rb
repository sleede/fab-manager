# frozen_string_literal:true

class CreatePriceCategories < ActiveRecord::Migration[4.2]
  def change
    create_table :price_categories do |t|
      t.string :name
      t.text :conditions

      t.timestamps null: false
    end
  end
end
