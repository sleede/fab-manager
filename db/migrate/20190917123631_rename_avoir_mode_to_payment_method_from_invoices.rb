# frozen_string_literal: true

# From this migration, this column will also be used to save the means of payment used to charge the customer
# This is due to Strong Customer Authentication changes, that don't store any more an stp_invoice_id in table
# "invoices". The new stp_payment_intent_id is not populated if the invoice total = 0 but we must know if the
# payment was made on site or online.
class RenameAvoirModeToPaymentMethodFromInvoices < ActiveRecord::Migration
  def change
    rename_column :invoices, :avoir_mode, :payment_method
  end
end
