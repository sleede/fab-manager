# frozen_string_literal: true

require 'test_helper'

class Cart::CheckCartServiceTest < ActiveSupport::TestCase
  setup do
    @panneaux = Product.find_by(slug: 'panneaux-de-mdf')
    @cart = Order.find_by(token: 'KbSmmD_gi9w_CrpwtK9OwA1666687433963')
  end

  test 'product is inactive in cart' do
    @panneaux.is_active = false
    @panneaux.save
    errors = Cart::CheckCartService.new.call(@cart)
    assert_equal errors[:details].length, 1
    assert_equal errors[:details].first[:errors].length, 1
    assert_equal errors[:details].first[:errors].first[:error], 'is_active'
    assert_equal errors[:details].first[:errors].first[:value], false
  end

  test 'product is out of stock in cart' do
    @panneaux.stock['external'] = 0
    @panneaux.save
    errors = Cart::CheckCartService.new.call(@cart)
    assert_equal errors[:details].length, 1
    assert_equal errors[:details].first[:errors].length, 1
    assert_equal errors[:details].first[:errors].first[:error], 'stock'
    assert_equal errors[:details].first[:errors].first[:value], 0
  end

  test 'product is less than quantity min in cart' do
    @panneaux.quantity_min = 2
    @panneaux.save
    errors = Cart::CheckCartService.new.call(@cart)
    assert_equal errors[:details].length, 1
    assert_equal errors[:details].first[:errors].length, 1
    assert_equal errors[:details].first[:errors].first[:error], 'quantity_min'
    assert_equal errors[:details].first[:errors].first[:value], 2
  end

  test 'product amount changed in cart' do
    @panneaux.amount = 600
    @panneaux.save
    errors = Cart::CheckCartService.new.call(@cart)
    assert_equal errors[:details].length, 1
    assert_equal errors[:details].first[:errors].length, 1
    assert_equal errors[:details].first[:errors].first[:error], 'amount'
    assert_equal errors[:details].first[:errors].first[:value], 600 / 100.0
  end
end
