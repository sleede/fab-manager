require 'test_helper'

class AvailabilityTest < ActiveSupport::TestCase
  test "length must be at least 1h" do
    a = Availability.new(start_at: Time.now, end_at: 15.minutes.from_now)
    assert a.invalid?
    assert a.errors.key?(:end_at)
  end

  test "if type available_type is 'machines' check that there is minimum 1 association" do
    a = Availability.new(start_at: Time.now, end_at: 2.hours.from_now, available_type: 'machines')
    assert a.invalid?
    assert a.errors.key?(:machine_ids)
  end
end
