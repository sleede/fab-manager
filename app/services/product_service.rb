# frozen_string_literal: true

# Provides methods for Product
class ProductService
  def self.list
    Product.all
  end
end
