class AddInvoiceIdToOrder < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :invoice, index: true, foreign_key: true
  end
end
