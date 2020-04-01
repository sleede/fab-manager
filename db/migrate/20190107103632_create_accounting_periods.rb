# frozen_string_literal:true

class CreateAccountingPeriods < ActiveRecord::Migration[4.2]
  def change
    create_table :accounting_periods do |t|
      t.date :start_at
      t.date :end_at
      t.datetime :closed_at
      t.integer :closed_by

      t.timestamps null: false
    end

    add_foreign_key :accounting_periods, :users, column: :closed_by, primary_key: :id

  end
end
