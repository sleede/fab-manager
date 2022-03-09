# frozen_string_literal: true

# OpenApiCallsCountTracings was an unused table probably from a wrong copy/paste. We removed this dead code.
class DropTableOpenAPICallsCountTracings < ActiveRecord::Migration[5.2]
  def up
    drop_table :open_api_calls_count_tracings
  end

  def down
    create_table :open_api_calls_count_tracings do |t|
      t.belongs_to :open_api_client, foreign_key: true, index: true
      t.integer :calls_count, null: false
      t.datetime :at, null: false
      t.timestamps null: false
    end
  end
end
