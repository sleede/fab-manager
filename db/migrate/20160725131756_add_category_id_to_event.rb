class AddCategoryIdToEvent < ActiveRecord::Migration
  def change
    add_reference :events, :category, index: true, foreign_key: true
  end
end
