# frozen_string_literal:true

class CreateExports < ActiveRecord::Migration[4.2]
  def change
    create_table :exports do |t|
      t.string :category
      t.string :type
      t.string :query

      t.timestamps null: false
    end
  end
end
