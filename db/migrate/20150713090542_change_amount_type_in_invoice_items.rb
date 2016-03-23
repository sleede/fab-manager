class ChangeAmountTypeInInvoiceItems < ActiveRecord::Migration
  def up
    change_column :invoice_items, :amount, 'integer USING CAST(amount AS integer)'
  end

  def down
    change_column :invoice_items, :amount, :string
  end
end
