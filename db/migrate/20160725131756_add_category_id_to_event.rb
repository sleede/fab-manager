# frozen_string_literal:true

class AddCategoryIdToEvent < ActiveRecord::Migration[4.2]
  def change
    add_reference :events, :category, index: true, foreign_key: true
  end
end
