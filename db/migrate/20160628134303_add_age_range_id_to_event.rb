# frozen_string_literal:true

class AddAgeRangeIdToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :age_range_id, :integer
  end
end
