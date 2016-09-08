class CreateEventPriceCategories < ActiveRecord::Migration
  def change
    create_table :event_price_categories do |t|
      t.belongs_to :event, index: true, foreign_key: true
      t.belongs_to :price_category, index: true, foreign_key: true
      t.integer :amount

      t.timestamps null: false
    end
  end
end
