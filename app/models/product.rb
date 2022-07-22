# frozen_string_literal: true

# Product is a model for the merchandise hold information of product in store
class Product < ApplicationRecord
  belongs_to :product_category

  has_and_belongs_to_many :machines

  validates_numericality_of :amount, greater_than: 0, allow_nil: true
end
