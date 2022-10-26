# frozen_string_literal: true

# Raised when the item's quantity < product's quantity min
class Cart::QuantityMinError < StandardError
end
