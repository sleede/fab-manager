class AddSubscriptionToExpireToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :subscription_to_expire, :boolean
  end
end
