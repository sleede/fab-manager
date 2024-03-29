# frozen_string_literal: true

# Provides methods for ProductCategory
class ProductCategoryService
  def self.list
    ProductCategory.left_outer_joins(:products)
                   .select('product_categories.*, count(products.*) filter (where is_active is true) as products_count')
                   .group('product_categories.id')
  end

  def self.destroy(product_category)
    ActiveRecord::Base.transaction do
      sub_categories = ProductCategory.where(parent_id: product_category.id)
      # remove product_category and sub-categories related id in product
      Product.where(product_category_id: sub_categories.map(&:id).push(product_category.id)).update(product_category_id: nil)
      # remove all sub-categories
      sub_categories.destroy_all
      product_category.destroy
    end
  end
end
