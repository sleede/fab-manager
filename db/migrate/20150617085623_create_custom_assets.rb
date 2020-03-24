# frozen_string_literal:true

class CreateCustomAssets < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_assets do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
