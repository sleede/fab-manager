# frozen_string_literal: true

# From this migration, we save the pending event reservations in database, instead of just creating them on the fly
class CreateCartItemEventReservation < ActiveRecord::Migration[5.2]
  def change
    create_table :cart_item_event_reservations do |t|
      t.integer :normal_tickets
      t.references :event, foreign_key: true
      t.references :operator_profile, foreign_key: { to_table: 'invoicing_profiles' }
      t.references :customer_profile, foreign_key: { to_table: 'invoicing_profiles' }

      t.timestamps
    end
  end
end
