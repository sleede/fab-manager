# frozen_string_literal: true

# From this migration we save the accounting lines in database rather than building them on-the-fly.
# This will improve performance for API based requests
class CreateAccountingLines < ActiveRecord::Migration[5.2]
  def change
    create_table :accounting_lines do |t|
      t.string :line_type
      t.string :journal_code
      t.datetime :date
      t.string :account_code
      t.string :account_label
      t.string :analytical_code
      t.references :invoice, foreign_key: true, index: true
      t.references :invoicing_profile, foreign_key: true, index: true
      t.integer :debit
      t.integer :credit
      t.string :currency
      t.string :summary

      t.timestamps
    end
  end
end
