# frozen_string_literal:true

class AddSubscriptionIdToInvoiceItems < ActiveRecord::Migration[4.2]
  def change
    add_column :invoice_items, :subscription_id, :integer
  end
end
