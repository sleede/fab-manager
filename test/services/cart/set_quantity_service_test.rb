# frozen_string_literal: true

require 'test_helper'

class Cart::SetQuantityServiceTest < ActiveSupport::TestCase
  setup do
    @panneaux = Product.find_by(slug: 'panneaux-de-mdf')
    @caisse_en_bois = Product.find_by(slug: 'caisse-en-bois')
    @cart1 = Order.find_by(token: 'KbSmmD_gi9w_CrpwtK9OwA1666687433963')
    @cart2 = Order.find_by(token: 'MkI5z9qVxe_YdNYCR_WN6g1666628074732')
    @cart3 = Order.find_by(token: '4bB96D-MlqJGBr5T8eui-g1666690417460')
  end

  test 'change quantity of product in cart' do
    cart = Cart::SetQuantityService.new.call(@cart1, @panneaux, 10)
    assert_equal cart.total, @panneaux.amount * 10
    assert_equal cart.order_items.length, 1
  end

  test 'change quantity of product greater than stock' do
    assert_raise Cart::OutStockError do
      Cart::SetQuantityService.new.call(@cart1, @panneaux, 1000)
    end
  end

  test 'cannot change quantity less than product quantity min' do
    cart = Cart::SetQuantityService.new.call(@cart3, @caisse_en_bois, 1)
    assert_equal cart.total, @caisse_en_bois.amount * @caisse_en_bois.quantity_min
    assert_equal cart.order_items.first.quantity, @caisse_en_bois.quantity_min
  end

  test 'cannot change quantity if product that isnt in cart' do
    assert_raise ActiveRecord::RecordNotFound do
      Cart::SetQuantityService.new.call(@cart2, @panneaux, 10)
    end
  end
end
