# frozen_string_literal: true

# Raised when deleting a product, if this product is used in orders
class CannotDeleteProductError < StandardError
end
