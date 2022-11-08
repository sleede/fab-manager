# frozen_string_literal: true

# ProductCategory's slugs should validate uniqness in database
class AddIndexOnProductCategorySlug < ActiveRecord::Migration[5.2]
  def change
    add_index :product_categories, :slug, unique: true
  end
end
