# frozen_string_literal: true

# Product is a model for the merchandise hold information of product in store
class Product < ApplicationRecord
  belongs_to :product_category

  has_and_belongs_to_many :machines

  has_many :product_files, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :product_files, allow_destroy: true, reject_if: :all_blank

  has_many :product_images, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :product_images, allow_destroy: true, reject_if: :all_blank

  has_many :product_stock_movements, dependent: :destroy
  accepts_nested_attributes_for :product_stock_movements, allow_destroy: true, reject_if: :all_blank

  validates :amount, numericality: { greater_than: 0, allow_nil: true }

  scope :active, -> { where(is_active: true) }
end
