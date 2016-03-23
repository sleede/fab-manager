class AddStpInvoiceIdToReservation < ActiveRecord::Migration
  def change
    add_column :reservations, :stp_invoice_id, :string
    add_index :reservations, :stp_invoice_id
  end
end
