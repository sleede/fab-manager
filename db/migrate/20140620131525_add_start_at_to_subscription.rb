# frozen_string_literal:true

class AddStartAtToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :start_at, :datetime
    Subscription.all.each do |s|
      s.update_columns(start_at: s.created_at)
    end
  end
end
