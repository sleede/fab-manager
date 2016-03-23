class AddAuthorIdToProject < ActiveRecord::Migration
  def change
    add_column :projects, :author_id, :integer
  end
end
