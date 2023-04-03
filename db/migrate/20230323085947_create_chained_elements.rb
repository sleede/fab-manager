# frozen_string_literal: true

# From this migration, we save the chained elements in a separate table instead of adding footprints in their tables (like in invoices)
# This will allows more flexibility for the models
class CreateChainedElements < ActiveRecord::Migration[6.1]
  def up
    create_table :chained_elements do |t|
      t.references :element, index: true, polymorphic: true, null: false
      t.integer :previous_id
      t.foreign_key :chained_elements, column: :previous_id, primary_key: :id
      t.jsonb :content, null: false
      t.string :footprint, null: false

      t.timestamps
    end

    execute <<~SQL.squish
      CREATE OR REPLACE RULE chained_elements_upd_protect AS ON UPDATE
      TO chained_elements
      WHERE (
        new.content <> old.content OR
        new.footprint <> old.footprint OR
        new.previous_id <> old.previous_id OR
        new.element_id <> old.element_id OR
        new.element_type <> old.element_type)
      DO INSTEAD NOTHING;
    SQL
  end

  def down
    execute <<~SQL.squish
      DROP RULE IF EXISTS chained_elements_upd_protect ON chained_elements;
    SQL
    drop_table :chained_elements
  end
end
