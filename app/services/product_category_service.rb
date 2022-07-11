# frozen_string_literal: true

# Provides methods for ProductCategory
class ProductCategoryService
  def self.list
    ProductCategory.all.order(parent_id: :asc, position: :asc)
  end

  def self.destroy(product_category)
    ProductCategory.where(parent_id: product_category.id).destroy_all
    product_category.destroy
  end
end
