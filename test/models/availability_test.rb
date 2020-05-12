# frozen_string_literal: true

require 'test_helper'

class AvailabilityTest < ActiveSupport::TestCase
  test 'any duration is allowed' do
    a = Availability.first
    a.end_at = a.start_at + 15.minutes
    assert a.valid?
  end

  test "if type available_type is 'machines' check that there is minimum 1 association" do
    a = Availability.where(available_type: 'machines').first
    a.machines_availabilities.destroy_all
    assert a.invalid?
    assert a.errors.key?(:machine_ids)
  end
end
