# frozen_string_literal: true

# From this migration, we save the file imports into the database.
# Currently, imports are limited to users import from a CSV file
class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.integer :user_id
      t.string :attachment
      t.string :update_field
      t.string :category
      t.text :results

      t.timestamps null: false
    end
  end
end
