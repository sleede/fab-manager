# frozen_string_literal: true

# From this migration, we save the pending machine/space/training reservations in database, instead of just creating them on the fly
class CreateCartItemReservation < ActiveRecord::Migration[5.2]
  def change
    create_table :cart_item_reservations do |t|
      t.references :reservable, polymorphic: true, index: { name: 'index_cart_item_reservations_on_reservable' }
      t.references :plan, foreign_key: true
      t.boolean :new_subscription
      t.references :customer_profile, foreign_key: { to_table: 'invoicing_profiles' }
      t.references :operator_profile, foreign_key: { to_table: 'invoicing_profiles' }
      t.string :type

      t.timestamps
    end
  end
end
