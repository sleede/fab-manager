# frozen_string_literal:true

class CreateSpacesAvailabilities < ActiveRecord::Migration[4.2]
  def change
    create_table :spaces_availabilities do |t|
      t.belongs_to :space, index: true, foreign_key: true
      t.belongs_to :availability, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
