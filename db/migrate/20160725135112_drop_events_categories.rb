# frozen_string_literal:true

class DropEventsCategories < ActiveRecord::Migration[4.2]
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
