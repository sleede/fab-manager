# frozen_string_literal: true

# From this migration we delete the footprint_debugs table became useless
class DropFootprintDebugs < ActiveRecord::Migration[6.1]
  def change
    drop_table :footprint_debugs do |t|
      t.string :footprint
      t.string :data
      t.string :klass

      t.timestamps
    end
  end
end
