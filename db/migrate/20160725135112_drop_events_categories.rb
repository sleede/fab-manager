class DropEventsCategories < ActiveRecord::Migration
  def up
    drop_table :events_categories
  end

  def down
    create_table :events_categories do |t|
      t.belongs_to :event, index: true
      t.belongs_to :category, index: true

      t.timestamps
    end
  end
end
