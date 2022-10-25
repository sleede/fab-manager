# frozen_string_literal: true

require 'test_helper'

class Cart::AddItemServiceTest < ActiveSupport::TestCase
  setup do
    @panneaux = Product.find_by(slug: 'panneaux-de-mdf')
    @caisse_en_bois = Product.find_by(slug: 'caisse-en-bois')
    @cart = Order.find_by(token: 'MkI5z9qVxe_YdNYCR_WN6g1666628074732')
  end

  test 'add a product to cart' do
    cart = Cart::AddItemService.new.call(@cart, @panneaux, 10)
    assert_equal cart.total, @panneaux.amount * 10
    assert_equal cart.order_items.length, 1
    assert_equal cart.order_items.first.amount, @panneaux.amount
    assert_equal cart.order_items.first.quantity, 10
  end

  test 'add a product with quantity min' do
    cart = Cart::AddItemService.new.call(@cart, @caisse_en_bois)
    assert_equal cart.total, @caisse_en_bois.amount * @caisse_en_bois.quantity_min
    assert_equal cart.order_items.length, 1
    assert_equal cart.order_items.first.amount, @caisse_en_bois.amount
    assert_equal cart.order_items.first.quantity, @caisse_en_bois.quantity_min
  end

  test 'add two product to cart' do
    cart = Cart::AddItemService.new.call(@cart, @panneaux, 10)
    cart = Cart::AddItemService.new.call(@cart, @caisse_en_bois)
    assert_equal cart.total, (@caisse_en_bois.amount * 5) + (@panneaux.amount * 10)
    assert_equal cart.order_items.length, 2
    assert_equal cart.order_items.first.amount, @panneaux.amount
    assert_equal cart.order_items.first.quantity, 10
    assert_equal cart.order_items.last.amount, @caisse_en_bois.amount
    assert_equal cart.order_items.last.quantity, 5
  end

  test 'cannot add a product out of stock' do
    assert_raise Cart::OutStockError do
      Cart::AddItemService.new.call(@cart, @caisse_en_bois, 101)
    end
  end

  test 'cannot add a product inactive' do
    assert_raise Cart::InactiveProductError do
      product_inactive = Product.find_by(slug: 'sticker-hello')
      Cart::AddItemService.new.call(@cart, product_inactive, 1)
    end
  end
end
