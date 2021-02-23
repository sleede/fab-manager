# frozen_string_literal:true

# From this migration, if the current Invoice is payed with Stripe, it will be stored in database
# using stp_payment_intent_id instead of stp_invoice_id
class AddStpPaymentIntentIdToInvoices < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :stp_payment_intent_id, :string
  end
end
