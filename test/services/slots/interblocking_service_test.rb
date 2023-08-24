# frozen_string_literal: true

require 'test_helper'

class Slots::InterblockingServiceTest < ActiveSupport::TestCase
  setup do
    @parent_space = spaces(:space_1)
    @child_space = Space.create!(name: 'space 1-1', default_places: 2, parent: @parent_space)
    @space_availability = availabilities(:availability_18)
    @space_slots = @space_availability.slots
    @machine_availability = availabilities(:availability_7)
    @machine_slots = @machine_availability.slots
    @machine = machines(:machine_1).tap { |m| m.update!(space: @child_space) }
  end

  test '#blocked_slots_for_spaces : no reservation' do
    assert_empty Slots::InterblockingService.new.blocked_slots_for_spaces([@parent_space], @space_slots)
    assert_empty Slots::InterblockingService.new.blocked_slots_for_spaces([@child_space], @space_slots)
  end

  test '#blocked_slots_for_spaces : reservation on parent space' do
    reservation = Reservation.create!(reservable: @parent_space, statistic_profile: statistic_profiles(:jdupont))
    SlotsReservation.create!(reservation: reservation, slot: @space_slots.first)

    assert_equal [@space_slots.first], Slots::InterblockingService.new.blocked_slots_for_spaces([@child_space], @space_slots)
    assert_empty Slots::InterblockingService.new.blocked_slots_for_spaces([@parent_space], @space_slots)
  end

  test '#blocked_slots_for_spaces : reservation on child space' do
    reservation = Reservation.create!(reservable: @child_space, statistic_profile: statistic_profiles(:jdupont))
    SlotsReservation.create!(reservation: reservation, slot: @space_slots.first)

    assert_equal [@space_slots.first], Slots::InterblockingService.new.blocked_slots_for_spaces([@parent_space], @space_slots)
    assert_empty Slots::InterblockingService.new.blocked_slots_for_spaces([@child_space], @space_slots)
  end

  test '#blocked_slots_for_spaces : reservation on child machine' do
    reservation = Reservation.create!(reservable: @machine, statistic_profile: statistic_profiles(:jdupont))
    machine_availability = Availability.create!(@space_availability.slice(:start_at, :end_at, :slot_duration)
                                                                   .merge(available_type: 'machines', machine_ids: [@machine.id]))

    slot = Slot.create!(availability: machine_availability, start_at: @space_slots.first.start_at, end_at: @space_slots.first.end_at)
    SlotsReservation.create!(reservation: reservation, slot: slot)

    assert_equal [@space_slots.first], Slots::InterblockingService.new.blocked_slots_for_spaces([@parent_space], @space_slots)
    assert_equal [@space_slots.first], Slots::InterblockingService.new.blocked_slots_for_spaces([@child_space], @space_slots)

    slot.update!(start_at: slot.start_at - 15.minutes, end_at: slot.end_at - 15.minutes)

    # still match when overlapping
    assert_equal [@space_slots.first], Slots::InterblockingService.new.blocked_slots_for_spaces([@parent_space], @space_slots)
    assert_equal [@space_slots.first], Slots::InterblockingService.new.blocked_slots_for_spaces([@child_space], @space_slots)

    slot.update!(start_at: slot.start_at - 45.minutes, end_at: slot.end_at - 45.minutes)

    # not overlapping anymore
    assert_empty Slots::InterblockingService.new.blocked_slots_for_spaces([@parent_space], @space_slots)
    assert_empty Slots::InterblockingService.new.blocked_slots_for_spaces([@child_space], @space_slots)
  end

  test '#blocked_slots_for_machines : no reservation' do
    assert_empty Slots::InterblockingService.new.blocked_slots_for_machines([@machine], @machine_slots)
  end

  test '#blocked_slots_for_machines : reservation on parent space' do
    reservation = Reservation.create!(reservable: @parent_space, statistic_profile: statistic_profiles(:jdupont))

    space_availability = Availability.create!(@machine_availability.slice(:start_at, :end_at, :slot_duration)
                                                                    .merge(available_type: 'space', space_ids: [@parent_space.id]))

    slot = Slot.create!(availability: space_availability, start_at: @machine_slots.first.start_at, end_at: @machine_slots.first.end_at)
    SlotsReservation.create!(reservation: reservation, slot: slot)

    assert_equal [@machine_slots.first], Slots::InterblockingService.new.blocked_slots_for_machines([@machine], @machine_slots)

    slot.update!(start_at: slot.start_at - 15.minutes, end_at: slot.end_at - 15.minutes)

    # still match when overlapping
    assert_equal [@machine_slots.first], Slots::InterblockingService.new.blocked_slots_for_machines([@machine], @machine_slots)

    slot.update!(start_at: slot.start_at - 45.minutes, end_at: slot.end_at - 45.minutes)

    # not overlapping anymore
    assert_empty Slots::InterblockingService.new.blocked_slots_for_machines([@machine], @machine_slots)
  end

  test '#blocked_slots_for_machines : reservation on child space' do
    reservation = Reservation.create!(reservable: @child_space, statistic_profile: statistic_profiles(:jdupont))

    space_availability = Availability.create!(@machine_availability.slice(:start_at, :end_at, :slot_duration)
                                                                    .merge(available_type: 'space', space_ids: [@child_space.id]))

    slot = Slot.create!(availability: space_availability, start_at: @machine_slots.first.start_at, end_at: @machine_slots.first.end_at)
    SlotsReservation.create!(reservation: reservation, slot: slot)

    assert_equal [@machine_slots.first], Slots::InterblockingService.new.blocked_slots_for_machines([@machine], @machine_slots)

    slot.update!(start_at: slot.start_at - 15.minutes, end_at: slot.end_at - 15.minutes)

    # still match when overlapping
    assert_equal [@machine_slots.first], Slots::InterblockingService.new.blocked_slots_for_machines([@machine], @machine_slots)

    slot.update!(start_at: slot.start_at - 45.minutes, end_at: slot.end_at - 45.minutes)

    # not overlapping anymore
    assert_empty Slots::InterblockingService.new.blocked_slots_for_machines([@machine], @machine_slots)
  end
end
