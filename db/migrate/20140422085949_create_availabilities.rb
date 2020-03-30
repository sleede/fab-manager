# frozen_string_literal:true

class CreateAvailabilities < ActiveRecord::Migration[4.2]
  def change
    create_table :availabilities do |t|
      t.datetime :start_at
      t.datetime :end_at
      t.string :available_type

      t.timestamps
    end
  end
end
