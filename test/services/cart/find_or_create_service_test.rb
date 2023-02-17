# frozen_string_literal: true

require 'test_helper'

class Cart::FindOrCreateServiceTest < ActiveSupport::TestCase
  setup do
    @jdupond = User.find_by(username: 'jdupond')
    @acamus = User.find_by(username: 'acamus')
    @admin = User.find_by(username: 'admin')
  end

  test 'anonymous user create a new cart' do
    cart = Cart::FindOrCreateService.new(nil).call(nil)
    assert_equal cart.state, 'cart'
    assert_equal cart.total, 0
    assert_nil cart.statistic_profile_id
    assert_nil cart.operator_profile_id
  end

  test 'user create a new cart' do
    cart = Cart::FindOrCreateService.new(@jdupond).call(nil)
    assert_equal cart.state, 'cart'
    assert_equal cart.statistic_profile_id, @jdupond.statistic_profile.id
    assert_equal cart.total, 0
    assert_equal cart.operator_profile_id, @jdupond.invoicing_profile.id
    assert_equal Order.where(statistic_profile_id: @jdupond.statistic_profile.id, state: 'cart').count, 1
  end

  test 'find cart by token' do
    cart = Cart::FindOrCreateService.new(nil).call('MkI5z9qVxe_YdNYCR_WN6g1666628074732')
    assert_equal cart.state, 'cart'
    assert_equal cart.total, 0
    assert_nil cart.statistic_profile_id
    assert_nil cart.operator_profile_id
  end

  test 'get last cart' do
    cart = Cart::FindOrCreateService.new(@acamus).call(nil)
    assert_equal cart.token, '9VWkmJDSx7QixRusL7ppWg1666628033284'
  end

  test 'cannot get cart of other user by token but last user cart is returned instead' do
    cart = Cart::FindOrCreateService.new(@jdupond).call('9VWkmJDSx7QixRusL7ppWg1666628033284')
    assert_not_equal cart.token, '9VWkmJDSx7QixRusL7ppWg1666628033284'
    assert_equal cart.state, 'cart'
    assert_equal cart.total, 0
    assert_equal cart.operator_profile_id, @jdupond.invoicing_profile.id
  end

  test 'migrate an anonymous cart to a newly logged user' do
    cart = Cart::FindOrCreateService.new(@jdupond).call('MkI5z9qVxe_YdNYCR_WN6g1666628074732')
    assert_equal cart.state, 'cart'
    assert_equal cart.total, 0
    assert_equal cart.statistic_profile_id, @jdupond.statistic_profile.id
    assert_equal cart.operator_profile_id, @jdupond.invoicing_profile.id
    assert_equal Order.where(statistic_profile_id: @jdupond.statistic_profile.id, state: 'cart').count, 1
  end

  test 'user have only one cart' do
    cart = Cart::FindOrCreateService.new(@acamus).call('MkI5z9qVxe_YdNYCR_WN6g1666628074732')
    assert_equal cart.token, '9VWkmJDSx7QixRusL7ppWg1666628033284'
    assert_equal cart.state, 'cart'
    assert_equal cart.total, 0
    assert_equal cart.statistic_profile_id, @acamus.statistic_profile.id
    assert_equal cart.operator_profile_id, @acamus.invoicing_profile.id
    assert_equal Order.where(statistic_profile_id: @acamus.statistic_profile.id, state: 'cart').count, 1
    assert_nil Order.find_by(token: 'MkI5z9qVxe_YdNYCR_WN6g1666628074732')
  end

  test 'admin get a cart for himself' do
    cart = Cart::FindOrCreateService.new(@admin, @admin).call(nil)
    assert_equal cart.state, 'cart'
    assert_equal cart.total, 262_500
    assert_equal cart.operator_profile_id, @admin.invoicing_profile.id
    assert_equal cart.statistic_profile_id, @admin.statistic_profile.id
    assert_equal Order.where(operator_profile_id: @admin.invoicing_profile.id, state: 'cart').count, 1
  end

  test 'admin create new cart for a member' do
    cart = Cart::FindOrCreateService.new(@admin, @acamus).call(nil)
    assert_not_nil cart
    assert_equal cart.statistic_profile_id, @acamus.statistic_profile.id
    assert_equal cart.operator_profile_id, @admin.invoicing_profile.id
    assert_equal 'cart', cart.state
    assert_equal 0, cart.total
  end

  test 'admin create new cart for a member then get it' do
    cart = Cart::FindOrCreateService.new(@admin, @acamus).call(nil)
    cart2 = Cart::FindOrCreateService.new(@admin).call(cart.token)
    assert_not_nil cart2
    assert_equal cart.token, cart2.token
  end
end
