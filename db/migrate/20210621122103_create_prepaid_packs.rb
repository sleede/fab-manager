# frozen_string_literal: true

# Prepaid-packs of hours for machines/spaces
class CreatePrepaidPacks < ActiveRecord::Migration[5.2]
  def change
    create_table :prepaid_packs do |t|
      t.references :priceable, polymorphic: true
      t.references :group, foreign_key: true
      t.integer :amount
      t.integer :minutes

      t.timestamps
    end
  end
end
