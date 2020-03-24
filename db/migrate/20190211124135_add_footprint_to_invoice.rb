# frozen_string_literal:true

class AddFootprintToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :footprint, :string
  end
end
