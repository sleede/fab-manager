class AddSlugToEventTheme < ActiveRecord::Migration
  def change
    add_column :event_themes, :slug, :string
    add_index :event_themes, :slug, unique: true
  end
end
