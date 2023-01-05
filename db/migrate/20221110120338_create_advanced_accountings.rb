# frozen_string_literal: true

# Advanced accouting parameters are stored in a dedicated table,
# with a polymorphic relation per object
class CreateAdvancedAccountings < ActiveRecord::Migration[5.2]
  def change
    create_table :advanced_accountings do |t|
      t.string :code
      t.string :analytical_section
      t.references :accountable, polymorphic: true, index: { name: 'index_advanced_accountings_on_accountable' }

      t.timestamps
    end
  end
end
