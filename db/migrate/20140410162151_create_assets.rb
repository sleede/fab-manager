# frozen_string_literal:true

class CreateAssets < ActiveRecord::Migration[4.2]
  def change
    create_table :assets do |t|
      t.references :viewable,  polymorphic: true
      t.string :attachment
      t.string :type

      t.timestamps
    end
  end
end
