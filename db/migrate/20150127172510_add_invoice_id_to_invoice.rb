class AddInvoiceIdToInvoice < ActiveRecord::Migration
  def change
    add_reference :invoices, :invoice, index: true
    add_column :invoices, :type, :string
  end
end
