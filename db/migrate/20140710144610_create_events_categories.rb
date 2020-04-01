# frozen_string_literal:true

class CreateEventsCategories < ActiveRecord::Migration[4.2]
  def change
    create_table :events_categories do |t|
      t.belongs_to :event, index: true
      t.belongs_to :category, index: true

      t.timestamps
    end
  end
end
