# frozen_string_literal:true

class AddTitleToProjectStep < ActiveRecord::Migration[4.2]
  def change
    add_column :project_steps, :title, :string
    remove_column :project_steps, :picture, :string
  end
end
