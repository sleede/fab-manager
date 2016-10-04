class RenameRangeToNameFromAgeRange < ActiveRecord::Migration
  rename_column :age_ranges, :range, :name
end
