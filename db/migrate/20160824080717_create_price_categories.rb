class CreatePriceCategories < ActiveRecord::Migration
  def change
    create_table :price_categories do |t|
      t.string :name
      t.text :description

      t.timestamps null: false
    end
  end
end
