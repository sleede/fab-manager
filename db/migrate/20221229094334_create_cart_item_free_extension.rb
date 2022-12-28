# frozen_string_literal: true

# From this migration, we save the pending free-extensions of subscriptions in database, instead of just creating them on the fly
class CreateCartItemFreeExtension < ActiveRecord::Migration[5.2]
  def change
    create_table :cart_item_free_extensions do |t|
      t.references :subscription, foreign_key: true
      t.datetime :new_expiration_date
      t.references :customer_profile, foreign_key: { to_table: 'invoicing_profiles' }

      t.timestamps
    end
  end
end
