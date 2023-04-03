# frozen_string_literal: true

require 'test_helper'

# Test the service returning the visibility window for availabilities
class Availabilities::VisibilityServiceTest < ActiveSupport::TestCase
  setup do
    @admin = User.find_by(username: 'admin')
    @no_subscription = User.find_by(username: 'jdupond')
    @with_subscription = User.find_by(username: 'kdumas')
    @with_1y_subscription = User.find_by(username: 'acamus')
    # from the fixtures:
    # - visibility_others = 1 month
    # - visibility_yearly = 3 months
  end

  test 'admin visibility for the coming month' do
    starting = Time.current.beginning_of_day
    ending = 1.month.from_now.end_of_day
    window = Availabilities::VisibilityService.new.visibility(@admin, 'space', starting, ending)
    assert_equal starting, window[0]
    assert_equal ending, window[1]
  end

  test 'admin visibility for the previous month' do
    starting = 1.month.ago.end_of_day
    ending = Time.current.beginning_of_day
    window = Availabilities::VisibilityService.new.visibility(@admin, 'space', starting, ending)
    assert_equal starting, window[0]
    assert_equal ending, window[1]
  end

  test 'admin visibility for the coming year' do
    starting = Time.current.beginning_of_day
    ending = 1.year.from_now.end_of_day
    window = Availabilities::VisibilityService.new.visibility(@admin, 'space', starting, ending)
    assert_equal starting, window[0]
    assert_equal ending, window[1]
  end

  test 'member visibility for the coming month' do
    starting = Time.current.beginning_of_day
    ending = 1.month.from_now.end_of_day
    window = Availabilities::VisibilityService.new.visibility(@no_subscription, 'space', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_datetimes_near 1.month.from_now, window[1]
  end

  test 'member visibility for the previous month' do
    starting = 1.month.ago.end_of_day
    ending = Time.current.beginning_of_day
    window = Availabilities::VisibilityService.new.visibility(@no_subscription, 'space', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_equal ending, window[1]
  end

  test 'member visibility for the coming year' do
    starting = Time.current.beginning_of_day
    ending = 1.year.from_now.end_of_day
    window = Availabilities::VisibilityService.new.visibility(@no_subscription, 'space', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_datetimes_near 1.month.from_now, window[1]
  end

  test 'subscriber visibility for the coming month' do
    starting = Time.current.beginning_of_day
    ending = 1.month.from_now.end_of_day
    window = Availabilities::VisibilityService.new.visibility(@with_subscription, 'space', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_datetimes_near 1.month.from_now, window[1]
  end

  test 'subscriber visibility for the previous month' do
    starting = 1.month.ago.end_of_day
    ending = Time.current.beginning_of_day
    window = Availabilities::VisibilityService.new.visibility(@with_subscription, 'space', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_equal ending, window[1]
  end

  test 'subscriber visibility for the coming year' do
    starting = Time.current.beginning_of_day
    ending = 1.year.from_now.end_of_day
    window = Availabilities::VisibilityService.new.visibility(@with_subscription, 'space', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_datetimes_near 1.month.from_now, window[1]
  end

  test '1 year subscriber visibility for the coming month' do
    starting = Time.current.beginning_of_day
    ending = 1.month.from_now.end_of_day
    window = Availabilities::VisibilityService.new.visibility(@with_1y_subscription, 'space', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_equal ending, window[1]
  end

  test '1 year subscriber visibility for the previous month' do
    starting = 1.month.ago.end_of_day
    ending = Time.current.beginning_of_day
    window = Availabilities::VisibilityService.new.visibility(@with_1y_subscription, 'space', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_equal ending, window[1]
  end

  test '1 year subscriber visibility for the coming year' do
    starting = Time.current.beginning_of_day
    ending = 1.year.from_now.end_of_day
    window = Availabilities::VisibilityService.new.visibility(@with_1y_subscription, 'space', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_datetimes_near 3.months.from_now, window[1]
  end

  test '1 year subscriber visibility for trainings in the coming year' do
    starting = Time.current.beginning_of_day
    ending = 1.year.from_now.end_of_day
    window = Availabilities::VisibilityService.new.visibility(@with_1y_subscription, 'training', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_datetimes_near 1.month.from_now, window[1]
  end

  test 'subscriber with plan custom visibility' do
    plan = @with_subscription.subscribed_plan
    plan.update(machines_visibility: 48)
    starting = Time.current.beginning_of_day
    ending = 1.month.from_now.end_of_day
    window = Availabilities::VisibilityService.new.visibility(@with_subscription, 'machines', starting, ending)
    assert_datetimes_near Time.current, window[0]
    assert_datetimes_near 48.hours.from_now, window[1]
  end
end
