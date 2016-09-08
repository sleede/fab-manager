class CreatePriceCategories < ActiveRecord::Migration
  def change
    create_table :price_categories do |t|
      t.string :name
      t.text :conditions

      t.timestamps null: false
    end
  end
end
