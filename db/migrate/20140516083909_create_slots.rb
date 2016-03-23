class CreateSlots < ActiveRecord::Migration
  def change
    create_table :slots do |t|
      t.datetime :start_at
      t.datetime :end_at
      t.belongs_to :reservation, index: true

      t.timestamps
    end
  end
end
