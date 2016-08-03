require 'test_helper'

class CouponTest < ActiveSupport::TestCase
  test 'coupon must have a valid percentage' do
    c = Coupon.new({code: 'DISCOUNT', percent_off: 800})
    assert c.invalid?
  end
end
