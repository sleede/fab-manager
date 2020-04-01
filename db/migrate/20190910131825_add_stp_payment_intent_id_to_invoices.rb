# frozen_string_literal:true

class AddStpPaymentIntentIdToInvoices < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :stp_payment_intent_id, :string
  end
end
