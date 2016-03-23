class AddPublishedAtToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :published_at, :datetime

    Project.find_each do |p|
      p.update_columns(published_at: p.updated_at)
    end
  end

  def down
    remove_column :projects, :published_at, :datetime
  end
end
