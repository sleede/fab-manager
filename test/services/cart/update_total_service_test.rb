# frozen_string_literal: true

require 'test_helper'

class Cart::UpdateTotalServiceTest < ActiveSupport::TestCase
  setup do
    @panneaux = Product.find_by(slug: 'panneaux-de-mdf')
  end

  test 'total equal to product amount multiplied quantity' do
    order = Order.new
    order.order_items.push OrderItem.new(orderable: @panneaux, amount: @panneaux.amount, quantity: 10)
    cart = Cart::UpdateTotalService.new.call(order)
    assert_equal cart.total, @panneaux.amount * 10
  end

  test 'total equal to zero if product offered' do
    order = Order.new
    order.order_items.push OrderItem.new(orderable: @panneaux, amount: @panneaux.amount, quantity: 10, is_offered: true)
    cart = Cart::UpdateTotalService.new.call(order)
    assert_equal cart.total, 0
  end
end
