class CreateEventsCategories < ActiveRecord::Migration
  def change
    create_table :events_categories do |t|
      t.belongs_to :event, index: true, foreign_key: true
      t.belongs_to :category, index: true, foreign_key: true

      t.timestamps
    end
  end
end
