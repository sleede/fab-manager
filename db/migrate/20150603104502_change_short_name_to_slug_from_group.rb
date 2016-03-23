class ChangeShortNameToSlugFromGroup < ActiveRecord::Migration
  def change
    rename_column :groups, :short_name, :slug
  end
end
