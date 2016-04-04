require 'test_helper'

class AvailabilityTest < ActiveSupport::TestCase
  test "length must be at least 1h" do
    a = Availability.new(start_at: Time.now, end_at: 15.minutes.from_now)
    assert a.invalid?
    assert a.errors.key?(:end_at)
  end
end
