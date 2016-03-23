class AddSubscriptionIdToInvoiceItems < ActiveRecord::Migration
  def change
    add_column :invoice_items, :subscription_id, :integer
  end
end
