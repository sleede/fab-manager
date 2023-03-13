# frozen_string_literal: true

require 'test_helper'

class ReservationLimitServiceTest < ActiveSupport::TestCase
  setup do
    @acamus = User.find_by(username: 'acamus')
    @admin = User.find_by(username: 'admin')
    @machine = Machine.first
    @plan = Plan.find(1)
  end

  test 'simple reservation without plan' do
    reservation = CartItem::MachineReservation.new(
      customer_profile: @acamus.invoicing_profile,
      operator_profile: @acamus.invoicing_profile,
      reservable: @machine,
      cart_item_reservation_slots_attributes: [{ slot_id: @machine.availabilities.first.slots.first.id }]
    )
    assert ReservationLimitService.authorized?(nil, @acamus, reservation, [])
  end

  test 'simple reservation with not limiting plan' do
    reservation = CartItem::MachineReservation.new(
      customer_profile: @acamus.invoicing_profile,
      operator_profile: @acamus.invoicing_profile,
      reservable: @machine,
      cart_item_reservation_slots_attributes: [{ slot_id: @machine.availabilities.first.slots.first.id }]
    )
    assert ReservationLimitService.authorized?(@plan, @acamus, reservation, [])
  end

  test 'simple reservation with limiting plan' do
    @plan.update(limiting: true, plan_limitations_attributes: [{ limitable_id: @machine.id, limitable_type: 'Machine', limit: 2 }])
    reservation = CartItem::MachineReservation.new(
      customer_profile: @acamus.invoicing_profile,
      operator_profile: @acamus.invoicing_profile,
      reservable: @machine,
      cart_item_reservation_slots_attributes: [{ slot_id: @machine.availabilities.first.slots.first.id }]
    )
    assert ReservationLimitService.authorized?(@plan, @acamus, reservation, [])
  end

  test 'reservation exceeds plan limit' do
    @plan.update(limiting: true, plan_limitations_attributes: [{ limitable_id: @machine.id, limitable_type: 'Machine', limit: 2 }])
    slots = Availabilities::AvailabilitiesService.new(@acamus)
                                                 .machines([@machine], @acamus, { start: Time.current, end: 10.days.from_now })

    reservation = CartItem::MachineReservation.new(
      customer_profile: @acamus.invoicing_profile,
      operator_profile: @acamus.invoicing_profile,
      reservable: @machine,
      cart_item_reservation_slots_attributes: [{ slot: slots[0] }, { slot: slots[1] }, { slot: slots[2] }]
    )
    assert_not ReservationLimitService.authorized?(@plan, @acamus, reservation, [])
  end

  test 'second reservation at plan limit' do
    @plan.update(limiting: true, plan_limitations_attributes: [{ limitable_id: @machine.id, limitable_type: 'Machine', limit: 2 }])
    slots = Availabilities::AvailabilitiesService.new(@acamus)
                                                 .machines([@machine], @acamus, { start: Time.current, end: 10.days.from_now })

    reservation = CartItem::MachineReservation.new(
      customer_profile: @acamus.invoicing_profile,
      operator_profile: @acamus.invoicing_profile,
      reservable: @machine,
      cart_item_reservation_slots_attributes: [{ slot: slots[0] }]
    )
    reservation2 = CartItem::MachineReservation.new(
      customer_profile: @acamus.invoicing_profile,
      operator_profile: @acamus.invoicing_profile,
      reservable: @machine,
      cart_item_reservation_slots_attributes: [{ slot: slots[1] }]
    )
    assert ReservationLimitService.authorized?(@plan, @acamus, reservation2, [reservation])
  end

  test 'second reservation exceeds plan limit' do
    @plan.update(limiting: true, plan_limitations_attributes: [{ limitable_id: @machine.id, limitable_type: 'Machine', limit: 2 }])
    slots = Availabilities::AvailabilitiesService.new(@acamus)
                                                 .machines([@machine], @acamus, { start: Time.current, end: 10.days.from_now })

    reservation = CartItem::MachineReservation.new(
      customer_profile: @acamus.invoicing_profile,
      operator_profile: @acamus.invoicing_profile,
      reservable: @machine,
      cart_item_reservation_slots_attributes: [{ slot: slots[0] }, { slot: slots[1] }]
    )
    reservation2 = CartItem::MachineReservation.new(
      customer_profile: @acamus.invoicing_profile,
      operator_profile: @acamus.invoicing_profile,
      reservable: @machine,
      cart_item_reservation_slots_attributes: [{ slot: slots[2] }]
    )
    assert_not ReservationLimitService.authorized?(@plan, @acamus, reservation2, [reservation])
  end

  test 'reservation of other resource should not conflict' do
    @plan.update(limiting: true, plan_limitations_attributes: [{ limitable_id: @machine.id, limitable_type: 'Machine', limit: 2 }])
    slots = Availabilities::AvailabilitiesService.new(@acamus)
                                                 .machines([@machine], @acamus, { start: Time.current, end: 10.days.from_now })

    reservation = CartItem::SpaceReservation.new(
      customer_profile: @acamus.invoicing_profile,
      operator_profile: @acamus.invoicing_profile,
      reservable: Space.first,
      cart_item_reservation_slots_attributes: [{ slot: Space.first.availabilities.first.slots.first },
                                               { slot: Space.first.availabilities.first.slots.last }]
    )
    reservation2 = CartItem::MachineReservation.new(
      customer_profile: @acamus.invoicing_profile,
      operator_profile: @acamus.invoicing_profile,
      reservable: @machine,
      cart_item_reservation_slots_attributes: [{ slot: slots[0] }]
    )
    assert ReservationLimitService.authorized?(@plan, @acamus, reservation2, [reservation])
  end

  test 'get plan limit' do
    @plan.update(limiting: true, plan_limitations_attributes: [{ limitable_id: @machine.id, limitable_type: 'Machine', limit: 2 }])
    assert_equal 2, ReservationLimitService.limit(@plan, @machine)
  end

  test 'get plan without limit' do
    assert_nil ReservationLimitService.limit(@plan, @machine)
  end
end
