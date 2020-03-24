# frozen_string_literal:true

class RemoveToCancelFromSubscription < ActiveRecord::Migration[4.2]
  def change
    remove_column :subscriptions, :to_cancel, :string
  end
end
