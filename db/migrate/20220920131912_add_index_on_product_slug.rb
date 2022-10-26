# frozen_string_literal: true

# Products' slugs should validate uniqness in database
class AddIndexOnProductSlug < ActiveRecord::Migration[5.2]
  def change
    add_index :products, :slug, unique: true
  end
end
