# frozen_string_literal:true

class AddSubscriptionToExpireToInvoices < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :subscription_to_expire, :boolean
  end
end
