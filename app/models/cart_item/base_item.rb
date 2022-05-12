# frozen_string_literal: true

# Items that can be added to the shopping cart
module CartItem; end

# This is an abstract class implemented by classes that can be added to the shopping cart
class CartItem::BaseItem
  attr_reader :errors

  def initialize(*)
    @errors = {}
  end

  def price
    { elements: {}, amount: 0 }
  end

  def name
    ''
  end

  # This method run validations at cart-level, possibly using the other items in the cart, to validate the current one.
  # Other validations that may occurs at record-level (ActiveRecord validations) can't be related to other items.
  def valid?(_all_items)
    true
  end

  def to_object; end

  def type
    ''
  end
end
