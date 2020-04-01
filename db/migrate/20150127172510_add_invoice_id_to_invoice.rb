# frozen_string_literal:true

class AddInvoiceIdToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_reference :invoices, :invoice, index: true
    add_column :invoices, :type, :string
  end
end
