class AddTagsToProject < ActiveRecord::Migration
  def change
    add_column :projects, :tags, :text
  end
end
