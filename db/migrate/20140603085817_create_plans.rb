class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.string :name
      t.integer :amount
      t.string :interval
      t.belongs_to :group, index: true
      t.string :stp_plan_id

      t.timestamps
    end
  end
end
