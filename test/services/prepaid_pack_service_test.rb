# frozen_string_literal: true

require 'test_helper'

class PrepaidPackServiceTest < ActiveSupport::TestCase
  setup do
    @acamus = User.find_by(username: 'acamus')
    @machine = Machine.first
  end

  test 'get user packs' do
    packs = PrepaidPackService.user_packs(@acamus, @machine)
    p = StatisticProfilePrepaidPack.where(statistic_profile_id: @acamus.statistic_profile.id)
    assert_not_empty packs
    assert_equal packs.length, 1
    assert_equal p.length, 2
    assert_equal packs.first.id, p.last.id
  end

  test 'total number of prepaid minutes available' do
    minutes_available = PrepaidPackService.minutes_available(@acamus, @machine)
    assert_equal minutes_available, 600
  end

  test 'update user pack minutes' do
    availabilities_service = Availabilities::AvailabilitiesService.new(@acamus)

    slots = availabilities_service.machines([@machine], @acamus, { start: Time.current, end: 1.day.from_now })
    reservation = Reservation.create(
      reservable_id: @machine.id,
      reservable_type: Machine.name,
      slots: [slots[0], slots[1]],
      statistic_profile_id: @acamus.statistic_profile.id
    )

    PrepaidPackService.update_user_minutes(@acamus, reservation)
    minutes_available = PrepaidPackService.minutes_available(@acamus, @machine)
    assert_equal minutes_available, 480
  end
end
