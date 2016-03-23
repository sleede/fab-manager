class RemoveToCancelFromSubscription < ActiveRecord::Migration
  def change
    remove_column :subscriptions, :to_cancel, :string
  end
end
