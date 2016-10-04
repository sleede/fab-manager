require 'test_helper'

class PriceCategoryTest < ActiveSupport::TestCase
  test 'price category name must be unique' do
    pc = PriceCategory.new({name: '- DE 25 ANS', conditions: 'Tarif préférentiel pour les jeunes'})
    assert pc.invalid?
    assert pc.errors[:name].present?
  end

  test 'associated price category cannot be destroyed' do
    pc = PriceCategory.find(1)
    assert_not pc.safe_destroy
    assert_not_empty PriceCategory.where(id: 1)
  end
end
