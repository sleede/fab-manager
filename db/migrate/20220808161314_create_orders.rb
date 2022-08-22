class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.belongs_to :statistic_profile, foreign_key: true
      t.integer :operator_id
      t.string :token
      t.string :reference
      t.string :state
      t.integer :amount

      t.timestamps
    end
  end
end
