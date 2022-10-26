# frozen_string_literal: true

# Raised when the item's amount != product's amount
class Cart::ItemAmountError < StandardError
end
