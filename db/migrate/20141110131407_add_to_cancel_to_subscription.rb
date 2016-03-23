class AddToCancelToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :to_cancel, :boolean, default: true
  end
end
