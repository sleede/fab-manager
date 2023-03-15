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
      cart_item_reservation_slots_attributes: [{ slot: slots[2] }, { slot: slots[3] }, { slot: slots[4] }]
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
    assert_equal 2, ReservationLimitService.limit(@plan, @machine).limit
  end

  test 'get plan without limit' do
    assert_nil ReservationLimitService.limit(@plan, @machine)
  end

  test 'get category limit' do
    category = MachineCategory.find(1)
    category.update(machine_ids: [@machine.id])
    @plan.update(limiting: true, plan_limitations_attributes: [{ limitable: category, limit: 4 }])
    assert_equal 4, ReservationLimitService.limit(@plan, @machine).limit
  end

  test 'machine limit should override the category limit' do
    category = MachineCategory.find(1)
    category.update(machine_ids: [@machine.id])
    @plan.update(limiting: true, plan_limitations_attributes: [{ limitable: @machine, limit: 2 }, { limitable: category, limit: 4 }])
    limit = ReservationLimitService.limit(@plan, @machine)
    assert_equal 2, limit.limit
    assert_equal @machine, limit.limitable
  end

  test 'reservation reaches the limit' do
    user = User.find_by(username: 'kdumas')
    plan = user.subscribed_plan
    plan.update(limiting: true, plan_limitations_attributes: [{ limitable: @machine, limit: 1 }])
    slots = Availabilities::AvailabilitiesService.new(user)
                                                 .machines([@machine], user, { start: Time.current, end: 10.days.from_now })
    reservation = Reservation.create!(
      statistic_profile: user.statistic_profile,
      reservable: @machine,
      slots_reservations_attributes: [{ slot: slots.last }]
    )
    reservation.reload
    assert_equal slots.last.start_at.to_date, ReservationLimitService.reached_limit_date(reservation)
  end

  test 'reservation does not reaches the limit' do
    user = User.find_by(username: 'kdumas')
    plan = user.subscribed_plan
    plan.update(limiting: true, plan_limitations_attributes: [{ limitable: @machine, limit: 2 }])
    slots = Availabilities::AvailabilitiesService.new(user)
                                                 .machines([@machine], user, { start: Time.current, end: 10.days.from_now })
    reservation = Reservation.create!(
      statistic_profile: user.statistic_profile,
      reservable: @machine,
      slots_reservations_attributes: [{ slot: slots.last }]
    )
    reservation.reload
    assert_nil ReservationLimitService.reached_limit_date(reservation)
  end
end
