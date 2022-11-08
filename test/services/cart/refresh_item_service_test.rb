# frozen_string_literal: true

require 'test_helper'

class Cart::RefreshItemServiceTest < ActiveSupport::TestCase
  setup do
    @panneaux = Product.find_by(slug: 'panneaux-de-mdf')
    @cart1 = Order.find_by(token: 'KbSmmD_gi9w_CrpwtK9OwA1666687433963')
    @cart2 = Order.find_by(token: 'MkI5z9qVxe_YdNYCR_WN6g1666628074732')
  end

  test 'refresh total and item amount if product change amount' do
    @panneaux.amount = 10_000
    @panneaux.save
    cart = Cart::RefreshItemService.new.call(@cart1, @panneaux)
    assert_equal cart.total, 10_000
    assert_equal cart.order_items.first.amount, 10_000
  end

  test 'cannot refresh total and item amount if product isnt in cart' do
    assert_raise ActiveRecord::RecordNotFound do
      Cart::RefreshItemService.new.call(@cart2, @panneaux)
    end
  end
end
