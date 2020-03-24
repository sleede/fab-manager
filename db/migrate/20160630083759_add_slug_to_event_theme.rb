# frozen_string_literal:true

class AddSlugToEventTheme < ActiveRecord::Migration[4.2]
  def change
    add_column :event_themes, :slug, :string
    add_index :event_themes, :slug, unique: true
  end
end
