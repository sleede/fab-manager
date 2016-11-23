require 'test_helper'

class CouponTest < ActiveSupport::TestCase
  test 'coupon must have a valid percentage' do
    c = Coupon.new({name: 'Amazing deal', code: 'DISCOUNT', percent_off: 200, validity_per_user: 'once'})
    assert c.invalid?
  end

  test 'expired coupon must return the proper status' do
    c = Coupon.find_by(code: 'XMAS10')
    assert c.status == 'expired'
  end

  test 'two coupons cannot have the same code' do
    c = Coupon.new({name: 'Summer deals', code: 'SUNNYFABLAB', percent_off: 15, validity_per_user: 'always'})
    assert c.invalid?
  end
end
