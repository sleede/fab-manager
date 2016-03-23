class CreateDatabaseProviders < ActiveRecord::Migration
  def change
    create_table :database_providers do |t|

      t.timestamps null: false
    end
  end
end
