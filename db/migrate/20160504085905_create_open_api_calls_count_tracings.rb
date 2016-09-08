class CreateOpenAPICallsCountTracings < ActiveRecord::Migration
  def change
    create_table :open_api_calls_count_tracings do |t|
      t.belongs_to :open_api_client, foreign_key: true, index: true
      t.integer :calls_count, null: false
      t.datetime :at, null: false
      t.timestamps null: false
    end
  end
end
