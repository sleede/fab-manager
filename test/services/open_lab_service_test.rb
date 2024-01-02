# frozen_string_literal: true

require 'test_helper'

# In the following tests, amounts are expressed in centimes, ie. 1000 = 1000 cts = 10,00 EUR
class OpenLabServiceTest < ActiveSupport::TestCase
  test "do not raise any error" do
    h = nil

    assert_nothing_raised do
      h = OpenLabService.to_hash(projects(:project_1))
    end

    assert_instance_of Hash, h
  end
end