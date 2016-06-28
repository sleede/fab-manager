class CreateOpenAPIClients < ActiveRecord::Migration
  def change
    create_table :open_api_clients do |t|
      t.string :name
      t.integer :calls_count, default: 0
      t.string :token
      t.timestamps null: false
    end
  end
end
