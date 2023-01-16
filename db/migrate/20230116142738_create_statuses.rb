# frozen_string_literal: true

# From this migration, we set statuses for projects (new, pending, done...)
class CreateStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :statuses do |t|
      t.string :label

      t.timestamps
    end
  end
end
