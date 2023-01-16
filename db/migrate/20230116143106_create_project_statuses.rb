# frozen_string_literal: true

# From this migration, we link status to their projects
class CreateProjectStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :project_statuses do |t|
      t.references :project, foreign_key: true
      t.references :status, foreign_key: true

      t.timestamps
    end
  end
end
