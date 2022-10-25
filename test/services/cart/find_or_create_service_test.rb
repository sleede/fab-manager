# frozen_string_literal: true

require 'test_helper'

class Cart::FindOrCreateServiceTest < ActiveSupport::TestCase
  setup do
    @jdupond = User.find_by(username: 'jdupond')
    @acamus = User.find_by(username: 'acamus')
    @admin = User.find_by(username: 'admin')
  end

  test 'anoymous user create a new cart' do
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
    assert_nil cart.operator_profile_id
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

  test 'cannot get cart of other user by token' do
    cart = Cart::FindOrCreateService.new(@jdupond).call('9VWkmJDSx7QixRusL7ppWg1666628033284')
    assert_equal cart.state, 'cart'
    assert_equal cart.total, 0
    assert_nil cart.operator_profile_id
    assert_not_equal cart.token, '9VWkmJDSx7QixRusL7ppWg1666628033284'
  end

  test 'migrate a cart to user' do
    cart = Cart::FindOrCreateService.new(@jdupond).call('MkI5z9qVxe_YdNYCR_WN6g1666628074732')
    assert_equal cart.state, 'cart'
    assert_equal cart.total, 0
    assert_equal cart.statistic_profile_id, @jdupond.statistic_profile.id
    assert_nil cart.operator_profile_id
    assert_equal Order.where(statistic_profile_id: @jdupond.statistic_profile.id, state: 'cart').count, 1
  end

  test 'user have only one cart' do
    cart = Cart::FindOrCreateService.new(@acamus).call('MkI5z9qVxe_YdNYCR_WN6g1666628074732')
    assert_equal cart.token, '9VWkmJDSx7QixRusL7ppWg1666628033284'
    assert_equal cart.state, 'cart'
    assert_equal cart.total, 0
    assert_equal cart.statistic_profile_id, @acamus.statistic_profile.id
    assert_nil cart.operator_profile_id
    assert_equal Order.where(statistic_profile_id: @acamus.statistic_profile.id, state: 'cart').count, 1
    assert_nil Order.find_by(token: 'MkI5z9qVxe_YdNYCR_WN6g1666628074732')
  end

  test 'admin get a cart' do
    cart = Cart::FindOrCreateService.new(@admin).call(nil)
    assert_equal cart.state, 'cart'
    assert_equal cart.total, 261_500
    assert_equal cart.operator_profile_id, @admin.invoicing_profile.id
    assert_nil cart.statistic_profile_id
    assert_equal Order.where(operator_profile_id: @admin.invoicing_profile.id, state: 'cart').count, 1
  end
end
