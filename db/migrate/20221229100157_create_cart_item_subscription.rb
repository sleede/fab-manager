# frozen_string_literal: true

# From this migration, we save the pending subscriptions in database, instead of just creating them on the fly
class CreateCartItemSubscription < ActiveRecord::Migration[5.2]
  def change
    create_table :cart_item_subscriptions do |t|
      t.references :plan, foreign_key: true
      t.datetime :start_at
      t.references :customer_profile, foreign_key: { to_table: 'invoicing_profiles' }

      t.timestamps
    end
  end
end
