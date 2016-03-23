class AddUniqueIndexToSlugFromGroup < ActiveRecord::Migration
  def change
    add_index :groups, :slug, unique: true
  end
end
