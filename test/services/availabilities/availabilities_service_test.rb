# frozen_string_literal: true

require 'test_helper'

# Test the service returning the availabilities for the given resources
class Availabilities::AvailabilitiesServiceTest < ActiveSupport::TestCase
  setup do
    @no_subscription = User.find_by(username: 'jdupond')
    @with_subscription = User.find_by(username: 'kdumas')
    @with_1y_subscription = User.find_by(username: 'acamus')
    @admin = User.find_by(username: 'admin')
  end

  test 'no machines availabilities during given window' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.machines([Machine.find(3)], @no_subscription,
                             { start: Time.current.beginning_of_day, end: 1.day.from_now.end_of_day })

    assert_empty slots
  end

  test 'no machines availabilities for user tags' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.machines([Machine.find(3)], @no_subscription,
                             { start: 2.days.from_now.beginning_of_day, end: 4.days.from_now.end_of_day })

    assert_empty slots
  end

  test 'no past availabilities for members' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.machines([Machine.find(2)], @no_subscription,
                             { start: Time.zone.parse('2015-06-15').beginning_of_day, end: Time.zone.parse('2015-06-15').end_of_day })

    assert_empty slots
  end

  test 'admin can see past availabilities further than 1 month' do
    service = Availabilities::AvailabilitiesService.new(@admin)
    slots = service.machines([Machine.find(2)], @no_subscription,
                             { start: Time.zone.parse('2015-06-15').beginning_of_day, end: Time.zone.parse('2015-06-15').end_of_day })

    assert_not_empty slots
  end

  test 'admin can see past availabilities in 1 month ago' do
    service = Availabilities::AvailabilitiesService.new(@admin)
    slots = service.trainings([Training.find(2)], @no_subscription, { start: 1.month.ago.beginning_of_day, end: 1.day.ago.end_of_day })

    assert_not_empty slots
    availability = Availability.find(20)
    assert_equal availability.slots.count, slots.count
    assert_equal availability.start_at, slots.first.start_at
    assert_equal availability.end_at, slots.first.end_at
  end

  test 'machines availabilities' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.machines([Machine.find(1)], @no_subscription,
                             { start: 2.days.from_now.beginning_of_day, end: 4.days.from_now.end_of_day })

    assert_not_empty slots
    availability = Availability.find(7)
    assert_equal availability.slots.count, slots.count
    assert_equal availability.start_at, slots.min_by(&:start_at).start_at
    assert_equal availability.end_at, slots.max_by(&:end_at).end_at
  end

  test '[member] machines availabilities with blocked slots' do
    space = Space.find(1)
    machine = Machine.find(1).tap { |m| m.update!(space: space) }
    reservation = Reservation.create!(reservable: space, statistic_profile: statistic_profiles(:jdupont))
    machine_availability = Availability.create!(availabilities(:availability_7).slice(:start_at, :end_at, :slot_duration)
                                                                                .merge(available_type: 'machines', machine_ids: [machine.id]))

    machine_slot = availabilities(:availability_7).slots.first
    slot = Slot.create!(availability: machine_availability, start_at: machine_slot.start_at, end_at: machine_slot.end_at)

    opts = { start: 2.days.from_now.beginning_of_day, end: 4.days.from_now.end_of_day }
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.machines([machine], @no_subscription, opts)
    assert_equal 7, slots.count

    SlotsReservation.create!(reservation: reservation, slot: slot)

    slots = service.machines([machine], @no_subscription, opts)
    assert_equal 5, slots.count
  end

  test '[admin] machines availabilities with blocked slots' do
    space = Space.find(1)
    machine = Machine.find(1).tap { |m| m.update!(space: space) }
    reservation = Reservation.create!(reservable: space, statistic_profile: statistic_profiles(:jdupont))
    machine_availability = Availability.create!(availabilities(:availability_7).slice(:start_at, :end_at, :slot_duration)
                                                                                .merge(available_type: 'machines', machine_ids: [machine.id]))

    machine_slot = availabilities(:availability_7).slots.first
    slot = Slot.create!(availability: machine_availability, start_at: machine_slot.start_at, end_at: machine_slot.end_at)

    opts = { start: 2.days.from_now.beginning_of_day, end: 4.days.from_now.end_of_day }
    service = Availabilities::AvailabilitiesService.new(@admin)
    slots = service.machines([machine], @admin, opts)
    assert_equal 7, slots.count

    SlotsReservation.create!(reservation: reservation, slot: slot)

    slots = service.machines([machine], @admin, opts)
    assert_equal 7, slots.count

    assert_equal 2, slots.count(&:is_blocked)
  end

  test 'spaces availabilities' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.spaces([Space.find(1)], @no_subscription, { start: 2.days.from_now.beginning_of_day, end: 4.days.from_now.end_of_day })

    assert_not_empty slots
    availability = Availability.find(18)
    assert_equal availability.slots.count, slots.count
    assert_equal availability.start_at, slots.min_by(&:start_at).start_at
    assert_equal availability.end_at, slots.max_by(&:end_at).end_at
  end

  test '[member] spaces availabilities with blocked slots' do
    space = Space.find(1)
    machine = machines(:machine_1).tap { |m| m.update!(space: space) }
    reservation = Reservation.create!(reservable: machine, statistic_profile: statistic_profiles(:jdupont))
    machine_availability = Availability.create!(availabilities(:availability_18).slice(:start_at, :end_at, :slot_duration)
                                                                                .merge(available_type: 'machines', machine_ids: [machine.id]))

    space_slot = availabilities(:availability_18).slots.first
    slot = Slot.create!(availability: machine_availability, start_at: space_slot.start_at, end_at: space_slot.end_at)

    opts = { start: 2.days.from_now.beginning_of_day, end: 4.days.from_now.end_of_day }
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.spaces([space], @no_subscription, opts)
    assert_equal 4, slots.count

    SlotsReservation.create!(reservation: reservation, slot: slot)

    slots = service.spaces([space], @no_subscription, opts)
    assert_equal 3, slots.count
  end

  test '[admin] spaces availabilities with blocked slots' do
    space = Space.find(1)
    machine = machines(:machine_1).tap { |m| m.update!(space: space) }
    reservation = Reservation.create!(reservable: machine, statistic_profile: statistic_profiles(:jdupont))
    machine_availability = Availability.create!(availabilities(:availability_18).slice(:start_at, :end_at, :slot_duration)
                                                                                .merge(available_type: 'machines', machine_ids: [machine.id]))

    space_slot = availabilities(:availability_18).slots.first
    slot = Slot.create!(availability: machine_availability, start_at: space_slot.start_at, end_at: space_slot.end_at)

    opts = { start: 2.days.from_now.beginning_of_day, end: 4.days.from_now.end_of_day }
    service = Availabilities::AvailabilitiesService.new(@admin)
    slots = service.spaces([space], @admin, opts)
    assert_equal 4, slots.count

    SlotsReservation.create!(reservation: reservation, slot: slot)

    slots = service.spaces([space], @admin, opts)
    assert_equal 4, slots.count

    assert_equal 1, slots.count(&:is_blocked)
  end

  test 'trainings availabilities' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    trainings = [Training.find(1), Training.find(2)]
    slots = service.trainings(trainings, @no_subscription, { start: Time.current.beginning_of_day, end: 2.days.from_now.end_of_day })

    assert_not_empty slots
    if Time.current.hour >= 6
      assert_equal Availability.find(2).slots.count, slots.count
    else
      assert_equal Availability.find(1).slots.count + Availability.find(2).slots.count, slots.count
    end
  end

  test 'events availability' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.events([Event.find(4)], @no_subscription,
                           { start: Time.current.beginning_of_day, end: 30.days.from_now.end_of_day })

    assert_not_empty slots
    availability = Availability.find(17)
    assert_equal availability.slots.count, slots.count
    assert_equal availability.start_at, slots.first.start_at
    assert_equal availability.end_at, slots.first.end_at
  end
end
