# frozen_string_literal: true

require 'test_helper'

class Cart::RemoveItemServiceTest < ActiveSupport::TestCase
  setup do
    @panneaux = Product.find_by(slug: 'panneaux-de-mdf')
    @cart1 = Order.find_by(token: 'KbSmmD_gi9w_CrpwtK9OwA1666687433963')
    @cart2 = Order.find_by(token: 'MkI5z9qVxe_YdNYCR_WN6g1666628074732')
  end

  test 'remove a product to cart' do
    cart = Cart::RemoveItemService.new.call(@cart1, @panneaux)
    assert_equal cart.total, 0
    assert_equal cart.order_items.length, 0
  end

  test 'cannot remove a product that isnt in cart' do
    assert_raise ActiveRecord::RecordNotFound do
      Cart::RemoveItemService.new.call(@cart2, @panneaux)
    end
  end
end
