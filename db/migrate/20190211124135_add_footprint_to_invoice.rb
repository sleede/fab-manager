class AddFootprintToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :footprint, :string
  end
end
