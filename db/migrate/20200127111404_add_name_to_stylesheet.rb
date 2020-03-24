# frozen_string_literal: true

# From this migration, we distinct multiple stylesheets by their name (previously there was one only one for the main theme override)
class AddNameToStylesheet < ActiveRecord::Migration[4.2]
  def change
    add_column :stylesheets, :name, :string
  end
end
