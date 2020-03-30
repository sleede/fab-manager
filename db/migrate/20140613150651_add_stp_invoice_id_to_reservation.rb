# frozen_string_literal:true

class AddStpInvoiceIdToReservation < ActiveRecord::Migration[4.2]
  def change
    add_column :reservations, :stp_invoice_id, :string
    add_index :reservations, :stp_invoice_id
  end
end
