# frozen_string_literal: true

# Product is a model for the merchandise.
# It holds data of products in the store
class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :product_category

  has_many :machines_products, dependent: :destroy
  has_many :machines, through: :machines_products

  has_many :product_files, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :product_files, allow_destroy: true, reject_if: :all_blank

  has_many :product_images, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :product_images, allow_destroy: true, reject_if: :all_blank

  has_many :product_stock_movements, dependent: :destroy
  accepts_nested_attributes_for :product_stock_movements, allow_destroy: true, reject_if: :all_blank

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :amount, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  scope :active, -> { where(is_active: true) }

  def main_image
    product_images.find_by(is_main: true)
  end
end
