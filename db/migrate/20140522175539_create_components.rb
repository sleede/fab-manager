# frozen_string_literal:true

class CreateComponents < ActiveRecord::Migration[4.2]
  def change
    create_table :components do |t|
      t.string :name, null: false
    end
  end
end