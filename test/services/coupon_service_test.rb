require 'test_helper'

class CouponServiceTest < ActiveSupport::TestCase
  setup do
    @jdupond = User.find_by(username: 'jdupond')
    @cash_coupon = Coupon.find_by(code: 'ZERG6H1R65H')
  end

  test 'user apply percent coupon to cart' do
    total = CouponService.new.apply(1000, 'SUNNYFABLAB', @jdupond.id)
    assert_equal 850, total
  end

  test 'user cannot apply excessive coupon to cart' do
    total = CouponService.new.apply(1000, @cash_coupon, @jdupond.id)
    assert_equal 1000, total
  end

  test 'user cannot apply invalid coupon to cart' do
    total = CouponService.new.apply(1000, 'INVALIDCODE', @jdupond.id)
    assert_equal 1000, total
  end

  test 'user cannot apply expired coupon to cart' do
    total = CouponService.new.apply(1000, 'XMAS10', @jdupond.id)
    assert_equal 1000, total
  end
end
