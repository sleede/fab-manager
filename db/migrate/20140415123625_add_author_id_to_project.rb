# frozen_string_literal:true

class AddAuthorIdToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :author_id, :integer
  end
end
