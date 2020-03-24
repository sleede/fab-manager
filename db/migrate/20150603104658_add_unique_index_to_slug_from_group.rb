# frozen_string_literal:true

class AddUniqueIndexToSlugFromGroup < ActiveRecord::Migration[4.2]
  def change
    add_index :groups, :slug, unique: true
  end
end
