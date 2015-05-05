class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :title
      t.text :description
      t.integer :availability_id
      t.integer :amount
      t.integer :reduced_amount
      t.integer :nb_total_places
      t.integer :recurrence_id

      t.timestamps
    end
    add_index :events, :availability_id
    add_index :events, :recurrence_id
  end
end
