# frozen_string_literal: true

require 'test_helper'

class SetCustomerServiceTest < ActiveSupport::TestCase
  setup do
    @admin = User.find_by(username: 'admin')
    @pjproudhon = User.find_by(username: 'pjproudhon')
  end

  test 'admin update the customer of an anonymous cart' do
    order = Order.find_by(token: '4bB96D-MlqJGBr5T8eui-g1666690417460')
    service = Cart::SetCustomerService.new(@admin)
    service.call(order, @pjproudhon)
    assert_equal @pjproudhon, order.user
    assert_equal @admin, order.operator_profile.user
  end

  test 'admin cannot update the customer of a paid cart' do
    order = Order.find_by(token: 'ttG9U892Bu0gbu8OnJkwTw1664892253183')
    service = Cart::SetCustomerService.new(@admin)
    service.call(order, @pjproudhon)
    assert_not_equal @pjproudhon, order.user
    assert_not_equal @admin, order.operator_profile.user
  end

  test 'member cannot update the customer himself' do
    order = Order.find_by(token: '4bB96D-MlqJGBr5T8eui-g1666690417460')
    service = Cart::SetCustomerService.new(@pjproudhon)
    service.call(order, @pjproudhon)
    assert_nil order.statistic_profile_id
    assert_nil order.operator_profile_id
  end
end
