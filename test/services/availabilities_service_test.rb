# frozen_string_literal: true

require 'test_helper'

# Test the service returning the availabilities for the given resources
class AvailabilitiesServiceTest < ActiveSupport::TestCase
  setup do
    @no_subscription = User.find_by(username: 'jdupond')
    @with_subscription = User.find_by(username: 'kdumas')
    @with_1y_subscription = User.find_by(username: 'acamus')
    @admin = User.find_by(username: 'admin')
  end

  test 'no machines availabilities during given window' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.machines([Machine.find(3)], @no_subscription,
                             { start: DateTime.current.beginning_of_day, end: 1.day.from_now.end_of_day })

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
                             { start: DateTime.parse('2015-06-15').beginning_of_day, end: DateTime.parse('2015-06-15').end_of_day })

    assert_empty slots
  end

  test 'admin cannot see past availabilities further than 1 month' do
    service = Availabilities::AvailabilitiesService.new(@admin)
    slots = service.machines([Machine.find(2)], @no_subscription,
                             { start: DateTime.parse('2015-06-15').beginning_of_day, end: DateTime.parse('2015-06-15').end_of_day })

    assert_empty slots
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

  test 'spaces availabilities' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.spaces([Space.find(1)], @no_subscription, { start: 2.days.from_now.beginning_of_day, end: 4.days.from_now.end_of_day })

    assert_not_empty slots
    availability = Availability.find(18)
    assert_equal availability.slots.count, slots.count
    assert_equal availability.start_at, slots.min_by(&:start_at).start_at
    assert_equal availability.end_at, slots.max_by(&:end_at).end_at
  end

  test 'trainings availabilities' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    trainings = [Training.find(1), Training.find(2)]
    slots = service.trainings(trainings, @no_subscription, { start: DateTime.current.beginning_of_day, end: 2.days.from_now.end_of_day })

    assert_not_empty slots
    if DateTime.current.hour >= 6
      assert_equal Availability.find(2).slots.count, slots.count
    else
      assert_equal Availability.find(1).slots.count + Availability.find(2).slots.count, slots.count
    end
  end

  test 'events availability' do
    service = Availabilities::AvailabilitiesService.new(@no_subscription)
    slots = service.events([Event.find(4)], @no_subscription,
                           { start: DateTime.current.beginning_of_day, end: 30.days.from_now.end_of_day })

    assert_not_empty slots
    availability = Availability.find(17)
    assert_equal availability.slots.count, slots.count
    assert_equal availability.start_at, slots.first.start_at
    assert_equal availability.end_at, slots.first.end_at
  end
end
