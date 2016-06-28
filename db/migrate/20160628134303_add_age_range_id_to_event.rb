class AddAgeRangeIdToEvent < ActiveRecord::Migration
  def change
    add_column :events, :age_range_id, :integer
  end
end
