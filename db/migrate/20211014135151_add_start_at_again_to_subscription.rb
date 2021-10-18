# frozen_string_literal: true

# From this migration we save again the start_at field to subscriptions (was removed in 20140703100457_change_start_at_to_expired_at_from_subscription.rb).
# This is used to schedule subscriptions start at a future date
class AddStartAtAgainToSubscription < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :start_at, :datetime
  end
end
