# frozen_string_literal: true

# Previously, the Slot table was holding data about reservations.
# This was a wrong assumption that leads to a bug.
# An Availability should have many slots but a slot can be related to multiple Reservations,
# so a slot must not hold data about a single reservation (like `offered`),these data
# should be stored in SlotsReservation instead.
class AddReservationFieldsToSlotsReservations < ActiveRecord::Migration[5.2]
  def up
    add_column :slots_reservations, :ex_start_at, :datetime
    add_column :slots_reservations, :ex_end_at, :datetime
    add_column :slots_reservations, :canceled_at, :datetime
    add_column :slots_reservations, :offered, :boolean, default: false

    execute <<-SQL
      UPDATE slots_reservations
      SET
        ex_start_at=slots.ex_start_at,
        ex_end_at=slots.ex_end_at,
        canceled_at=slots.canceled_at,
        offered=slots.offered
      FROM slots
      WHERE slots_reservations.slot_id = slots.id
    SQL

    remove_column :slots, :ex_start_at
    remove_column :slots, :ex_end_at
    remove_column :slots, :canceled_at
    remove_column :slots, :offered
    remove_column :slots, :destroying

    # we gonna keep only only one slot (remove duplicates) because data is now hold in slots_reservations

    # update slots_reservation.slot_id
    execute <<-SQL
      UPDATE slots_reservations
      SET slot_id=r.kept
      FROM (
          SELECT count(*), start_at, end_at, availability_id, min(id) AS kept, array_agg(id) AS all_ids
          FROM slots
          GROUP BY start_at, end_at, availability_id
          HAVING count(*) > 1) as r
      WHERE slot_id = ANY(r.all_ids);
    SQL

    # remove useless slots
    execute <<-SQL
      WITH same_slots AS (
          SELECT count(*), start_at, end_at, availability_id, min(id) AS kept, array_agg(id) AS all_ids
          FROM slots
          GROUP BY start_at, end_at, availability_id
          HAVING count(*) > 1
      )
      DELETE FROM slots
      WHERE id IN (SELECT unnest(all_ids) FROM same_slots)
      AND id NOT IN (SELECT kept FROM same_slots);
    SQL
  end

  def down
    execute <<-SQL
      DO
      $$
      DECLARE
          sr_group RECORD;
          slot slots%ROWTYPE;
          new_slot_id slots.id%TYPE;
          curr_slot_reservation_id slots_reservations.id%TYPE;
      BEGIN
          FOR sr_group IN
              SELECT count(*), array_agg(id) AS all_ids, slot_id
              FROM slots_reservations
              GROUP BY slot_id
              HAVING count(*) > 1
          LOOP
              SELECT * INTO slot FROM slots WHERE id = sr_group.slot_id;
              FOR curr_slot_reservation_id IN
                  SELECT unnest(sr_group.all_ids[2:])
              LOOP
                  INSERT INTO slots (start_at, end_at, created_at, updated_at, availability_id)
                  VALUES (slot.start_at, slot.end_at, now(), now(), slot.availability_id)
                  RETURNING id INTO new_slot_id;
                  UPDATE slots_reservations
                  SET slot_id=new_slot_id
                  WHERE id=curr_slot_reservation_id;
              END LOOP;
          END LOOP;
      END;
      $$
    SQL

    add_column :slots, :ex_start_at, :datetime
    add_column :slots, :ex_end_at, :datetime
    add_column :slots, :canceled_at, :datetime
    add_column :slots, :offered, :boolean, default: false
    add_column :slots, :destroying, :boolean, default: false

    execute <<-SQL
      UPDATE slots
      SET
        ex_start_at=slots_reservations.ex_start_at,
        ex_end_at=slots_reservations.ex_end_at,
        canceled_at=slots_reservations.canceled_at,
        offered=slots_reservations.offered
      FROM slots_reservations
      WHERE slots_reservations.slot_id = slots.id
    SQL

    remove_column :slots_reservations, :ex_start_at
    remove_column :slots_reservations, :ex_end_at
    remove_column :slots_reservations, :canceled_at
    remove_column :slots_reservations, :offered
  end
end
