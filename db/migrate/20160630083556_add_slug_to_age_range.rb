# frozen_string_literal:true

class AddSlugToAgeRange < ActiveRecord::Migration[4.2]
  def change
    add_column :age_ranges, :slug, :string
    add_index :age_ranges, :slug, unique: true
  end
end
