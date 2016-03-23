class CreateMachinesPricings < ActiveRecord::Migration
  def change
    create_table :machines_pricings do |t|
      t.belongs_to :machine, index: true
      t.belongs_to :group, index: true
      t.integer :not_subscribe_amount
      t.integer :month_amount
      t.integer :year_amount

      t.timestamps
    end
  end
end
