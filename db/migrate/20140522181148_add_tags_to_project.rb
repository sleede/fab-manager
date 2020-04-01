# frozen_string_literal:true

class AddTagsToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :tags, :text
  end
end
