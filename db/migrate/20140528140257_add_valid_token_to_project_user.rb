# frozen_string_literal:true

class AddValidTokenToProjectUser < ActiveRecord::Migration[4.2]
  def change
    add_column :project_users, :valid_token, :string
  end
end
