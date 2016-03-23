class AddIsValidToProjectUser < ActiveRecord::Migration
  def change
    add_column :project_users, :is_valid, :boolean, default: false
  end
end
