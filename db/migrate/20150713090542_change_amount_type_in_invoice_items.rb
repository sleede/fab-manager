# frozen_string_literal:true

class ChangeAmountTypeInInvoiceItems < ActiveRecord::Migration[4.2]
  def up
    change_column :invoice_items, :amount, 'integer USING CAST(amount AS integer)'
  end

  def down
    change_column :invoice_items, :amount, :string
  end
end
