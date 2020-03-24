# frozen_string_literal:true

class AddMergedAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :merged_at, :datetime
  end
end
