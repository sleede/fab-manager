# frozen_string_literal:true

class CreateAuthProviders < ActiveRecord::Migration[4.2]
  def change
    create_table :auth_providers do |t|
      t.string :name
      t.string :type
      t.string :status

      t.timestamps null: false
    end
  end
end
