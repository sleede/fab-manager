# frozen_string_literal: true

# From this migration, we save the file imports into the database.
# Currently, imports are limited to users import from a CSV file
class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.integer :author_id
      t.string :attachment

      t.timestamps null: false
    end
  end
end
