# frozen_string_literal:true

class CreateDatabaseProviders < ActiveRecord::Migration[4.2]
  def change
    create_table :database_providers do |t|

      t.timestamps null: false
    end
  end
end
