class AddTitleToProjectStep < ActiveRecord::Migration
  def change
    add_column :project_steps, :title, :string
    remove_column :project_steps, :picture, :string
  end
end
