class AddValidTokenToProjectUser < ActiveRecord::Migration
  def change
    add_column :project_users, :valid_token, :string
  end
end
