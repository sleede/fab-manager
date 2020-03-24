# frozen_string_literal:true

class AddSlugToCategories < ActiveRecord::Migration[4.2]
  def change
    add_column :categories, :slug, :string
    add_index :categories, :slug, unique: true
  end
end
