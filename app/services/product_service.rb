# frozen_string_literal: true

# Provides methods for Product
class ProductService
  def self.list
    Product.all
  end

  # amount params multiplied by hundred
  def self.amount_multiplied_by_hundred(amount)
    if amount.present?
      v = amount.to_f

      return nil if v.zero?

      return v * 100
    end
    nil
  end
end
