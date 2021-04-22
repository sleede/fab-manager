# frozen_string_literal: true

# Items that can be added to the shopping cart
module CartItem; end

# This is an abstract class implemented by classes that can be added to the shopping cart
class CartItem::BaseItem
  self.abstract_class = true

  def price
    { elements: {}, amount: 0 }
  end
end
