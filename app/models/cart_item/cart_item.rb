# frozen_string_literal: true

# Items that can be added to the shopping cart
module CartItem
  def self.table_name_prefix
    'cart_item_'
  end
end
