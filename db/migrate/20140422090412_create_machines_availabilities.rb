# frozen_string_literal:true

class CreateMachinesAvailabilities < ActiveRecord::Migration[4.2]
  def change
    create_table :machines_availabilities do |t|
      t.belongs_to :machine, index: true
      t.belongs_to :availability, index: true
    end
  end
end
