# frozen_string_literal: true

require 'test_helper'

class Cart::SetOfferServiceTest < ActiveSupport::TestCase
  setup do
    @caisse_en_bois = Product.find_by(slug: 'caisse-en-bois')
    @filament = Product.find_by(slug: 'filament-pla-blanc')
    @cart = Order.find_by(token: '0DKxbAOzSXRx-amXyhmDdg1666691976019')
  end

  test 'set offer product in cart' do
    cart = Cart::SetOfferService.new.call(@cart, @caisse_en_bois, true)
    assert_equal cart.total, 1000
    assert_equal cart.order_items.first.amount, @caisse_en_bois.amount
    assert_equal cart.order_items.first.is_offered, true
  end

  test 'cannot set offer if product that isnt in cart' do
    assert_raise ActiveRecord::RecordNotFound do
      Cart::SetOfferService.new.call(@cart, @filament, true)
    end
  end
end
