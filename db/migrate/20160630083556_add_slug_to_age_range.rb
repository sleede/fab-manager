class AddSlugToAgeRange < ActiveRecord::Migration
  def change
    add_column :age_ranges, :slug, :string
    add_index :age_ranges, :slug, unique: true
  end
end
