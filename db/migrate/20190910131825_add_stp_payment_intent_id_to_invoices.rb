class AddStpPaymentIntentIdToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :stp_payment_intent_id, :string
  end
end
