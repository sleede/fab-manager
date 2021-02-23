# frozen_string_literal: true

require 'test_helper'

# In the following tests, amounts are expressed in centimes, ie. 1000 = 1000 cts = 10,00 EUR
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

  test 'ventilate 15 percent coupon' do
    coupon = Coupon.find_by(code: 'SUNNYFABLAB')
    total = CouponService.new.ventilate(1000, 500, coupon)
    assert_equal 425, total
  end

  test 'ventilate 100 euros coupon' do
    coupon = Coupon.find_by(code: 'GIME3EUR')
    total = CouponService.new.ventilate(1000, 500, coupon)
    assert_equal 350, total
  end
end
