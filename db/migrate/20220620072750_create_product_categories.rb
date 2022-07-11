class CreateProductCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :product_categories do |t|
      t.string :name
      t.string :slug
      t.integer :parent_id, index: true
      t.integer :position

      t.timestamps
    end
  end
end
