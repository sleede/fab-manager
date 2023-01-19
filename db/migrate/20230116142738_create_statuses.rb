# frozen_string_literal: true

# From this migration, we set statuses for projects (new, pending, done...)
class CreateStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :statuses do |t|
      t.string :label

      t.timestamps
    end
    add_reference :projects, :status, index: true, foreign_key: true
  end
end
