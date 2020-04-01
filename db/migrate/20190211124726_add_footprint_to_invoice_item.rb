# frozen_string_literal:true

class AddFootprintToInvoiceItem < ActiveRecord::Migration[4.2]
  def change
    add_column :invoice_items, :footprint, :string
  end
end
