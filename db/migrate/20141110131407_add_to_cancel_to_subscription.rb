# frozen_string_literal:true

class AddToCancelToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :to_cancel, :boolean, default: true
  end
end
