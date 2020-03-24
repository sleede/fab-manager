# frozen_string_literal:true

class RenameRangeToNameFromAgeRange < ActiveRecord::Migration[4.2]
  rename_column :age_ranges, :range, :name
end
