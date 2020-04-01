# frozen_string_literal:true

class ChangeShortNameToSlugFromGroup < ActiveRecord::Migration[4.2]
  def change
    rename_column :groups, :short_name, :slug
  end
end
