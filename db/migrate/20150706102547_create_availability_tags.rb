class CreateAvailabilityTags < ActiveRecord::Migration
  def change
    create_table :availability_tags do |t|
      t.belongs_to :availability, index: true, foreign_key: true
      t.belongs_to :tag, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
