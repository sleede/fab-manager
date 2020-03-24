# frozen_string_literal:true

class AddIsValidToProjectUser < ActiveRecord::Migration[4.2]
  def change
    add_column :project_users, :is_valid, :boolean, default: false
  end
end
