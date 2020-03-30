# frozen_string_literal:true

class RemoveStpInvoiceIdFromReservations < ActiveRecord::Migration[4.2]
  def change
    remove_column :reservations, :stp_invoice_id, :string
  end
end
