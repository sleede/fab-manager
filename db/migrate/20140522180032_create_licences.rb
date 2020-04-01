# frozen_string_literal:true

class CreateLicences < ActiveRecord::Migration[4.2]
  def change
    create_table :licences do |t|
      t.string :name, null: false
      t.text :description
    end
  end
end
