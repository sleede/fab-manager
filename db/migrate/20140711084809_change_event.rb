# frozen_string_literal:true

class ChangeEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :availability_id, :integer
    add_index :events, :availability_id
    add_column :events, :amount, :integer
    add_column :events, :reduced_amount, :integer
    add_column :events, :nb_total_places, :integer
    add_column :events, :nb_free_places, :integer
  end
end
