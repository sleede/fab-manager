# frozen_string_literal: true

# Services around slots
module Slots; end

# Check the reservation status of a slot
class Slots::InterblockingService
  # returns an array of slots
  # @param spaces [ActiveRecord::Relation<Space>]
  # @param slots [ActiveRecord::Relation<Slot>]
  def blocked_slots_for_spaces(spaces, slots)
    blocking_slots_start_at_end_at = []
    spaces.each do |space|
      parent_and_child_space_ids = [space.parent_id, space.child_ids].flatten.compact
      blocking_slots_start_at_end_at << Slot.joins(slots_reservations: :reservation)
                                            .where(slots_reservations: { canceled_at: nil },
                                                   reservations: { reservable_type: 'Space',
                                                                   reservable_id: parent_and_child_space_ids })
                                            .pluck(:start_at, :end_at)
                                            .map { |d| %i[start_at end_at].zip(d).to_h }
      child_machine_ids = Machine.where(space_id: [space.id, parent_and_child_space_ids].flatten)
      blocking_slots_start_at_end_at << Slot.joins(slots_reservations: :reservation)
                                            .where(slots_reservations: { canceled_at: nil },
                                                   reservations: { reservable_type: 'Machine',
                                                                   reservable_id: child_machine_ids })
                                            .pluck(:start_at, :end_at)
                                            .map { |d| %i[start_at end_at].zip(d).to_h }
    end
    blocking_slots_start_at_end_at = blocking_slots_start_at_end_at.flatten&.uniq || []

    blocked_slots(slots, blocking_slots_start_at_end_at)
  end

  def blocked_slots_for_machines(machines, slots)
    blocking_slots_start_at_end_at = []
    machines.each do |machine|
      parent_space_ids = machine.space&.path_ids
      next unless parent_space_ids&.any?

      blocking_slots_start_at_end_at << Slot.joins(slots_reservations: :reservation)
                                            .where(slots_reservations: { canceled_at: nil }, reservations: { reservable_type: 'Space',
                                                                                                             reservable_id: parent_space_ids })
                                            .pluck(:start_at, :end_at)
                                            .map { |d| %i[start_at end_at].zip(d).to_h }
    end
    blocking_slots_start_at_end_at = blocking_slots_start_at_end_at.flatten&.uniq || []

    blocked_slots(slots, blocking_slots_start_at_end_at)
  end

  private

  def blocked_slots(slots, blocking_slots)
    slots.select do |slot|
      blocking_slots.find do |blocking_slot|
        blocking_slot[:start_at] < slot.end_at && slot.start_at < blocking_slot[:end_at]
      end
    end
  end
end
