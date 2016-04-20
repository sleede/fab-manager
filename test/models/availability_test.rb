require 'test_helper'

class AvailabilityTest < ActiveSupport::TestCase
  test "length must be at least 1h" do
    a = Availability.first
    a.end_at = a.start_at + 15.minutes
    assert a.invalid?
    assert a.errors.key?(:end_at)
  end

  test "if type available_type is 'machines' check that there is minimum 1 association" do
    a = Availability.where(available_type: 'machines').first
    a.machines_availabilities.destroy_all
    assert a.invalid?
    assert a.errors.key?(:machine_ids)
  end
end
