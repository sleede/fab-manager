# frozen_string_literal: true

# From this migration we save the association between a Reservation and a PrepaidPack to keep the
# usage history.
class CreatePrepaidPackReservations < ActiveRecord::Migration[5.2]
  def change
    create_table :prepaid_pack_reservations do |t|
      t.references :statistic_profile_prepaid_pack, foreign_key: true, index: { name: 'index_prepaid_pack_reservations_on_sp_prepaid_pack_id' }
      t.references :reservation, foreign_key: true
      t.integer :consumed_minutes

      t.timestamps
    end
  end
end
