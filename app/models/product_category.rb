# frozen_string_literal: true

# Category is a first-level filter, used to categorize Products.
# It is mandatory to choose a Category when creating a Product.
class ProductCategory < ApplicationRecord
  validates :name, :slug, presence: true

  belongs_to :parent, class_name: 'ProductCategory'
  has_many :children, class_name: 'ProductCategory', foreign_key: :parent_id

  acts_as_list scope: :parent, top_of_list: 0
end
