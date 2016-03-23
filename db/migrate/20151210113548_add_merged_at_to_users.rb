class AddMergedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :merged_at, :datetime
  end
end
