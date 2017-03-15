require 'test_helper'

class CouponTest < ActiveSupport::TestCase

  test 'valid coupon with percentage' do
    c = Coupon.new({name: 'Hot deals', code: 'HOT15', percent_off: 15, validity_per_user: 'once', valid_until: (Time.now + 2.weeks), max_usages: 100, active: true})
    assert c.valid?
    assert_equal 'active', c.status, 'Invalid coupon status'
    assert_equal 'percent_off', c.type, 'Invalid coupon type'
  end

  test 'coupon must have a valid percentage' do
    c = Coupon.new({name: 'Amazing deal', code: 'DISCOUNT', percent_off: 200, validity_per_user: 'once'})
    assert c.invalid?
  end

  test 'expired coupon must return the proper status' do
    c = Coupon.find_by(code: 'XMAS10')
    assert_equal 'expired', c.status
  end

  test 'two coupons cannot have the same code' do
    c = Coupon.new({name: 'Summer deals', code: 'SUNNYFABLAB', percent_off: 15, validity_per_user: 'always'})
    assert c.invalid?
  end

  test 'valid coupon with cash amount' do
    c = Coupon.new({name: 'Essential Box', code: 'KWXX2M', amount_off: 2000, validity_per_user: 'once', max_usages: 1, active: true})
    assert c.valid?
    assert_equal 'active', c.status, 'Invalid coupon status'
    assert_equal 'amount_off', c.type, 'Invalid coupon type'
  end

  test 'coupon with cash amount cannot be used with cheaper cart' do
    c = Coupon.new({name: 'Premium Box', code: '6DDX2T44MQ', amount_off: 20000, validity_per_user: 'once', max_usages: 1, active: true})
    assert_equal 'amount_exceeded', c.status(User.find_by(username: 'jdupond').id, 2000)
  end
end
