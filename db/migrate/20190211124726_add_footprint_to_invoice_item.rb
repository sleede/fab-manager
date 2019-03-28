class AddFootprintToInvoiceItem < ActiveRecord::Migration
  def change
    add_column :invoice_items, :footprint, :string
  end
end
