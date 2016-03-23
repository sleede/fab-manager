class CreateMachinesAvailabilities < ActiveRecord::Migration
  def change
    create_table :machines_availabilities do |t|
      t.belongs_to :machine, index: true
      t.belongs_to :availability, index: true
    end
  end
end
