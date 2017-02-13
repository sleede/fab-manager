class CreateSpacesAvailabilities < ActiveRecord::Migration
  def change
    create_table :spaces_availabilities do |t|
      t.belongs_to :space, index: true, foreign_key: true
      t.belongs_to :availability, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
