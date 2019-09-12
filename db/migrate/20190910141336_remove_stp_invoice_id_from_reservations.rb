class RemoveStpInvoiceIdFromReservations < ActiveRecord::Migration
  def change
    remove_column :reservations, :stp_invoice_id, :string
  end
end
