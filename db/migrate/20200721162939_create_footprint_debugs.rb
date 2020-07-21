# frozen_string_literal: true

# This table saves the original data used to create footprints, this allows
# to debug invalid footprints
class CreateFootprintDebugs < ActiveRecord::Migration[5.2]
  def change
    create_table :footprint_debugs do |t|
      t.string :footprint
      t.string :data
      t.string :klass

      t.timestamps
    end
  end
end
