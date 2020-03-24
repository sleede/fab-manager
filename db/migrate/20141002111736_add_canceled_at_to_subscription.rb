# frozen_string_literal:true

class AddCanceledAtToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :canceled_at, :datetime
  end
end
