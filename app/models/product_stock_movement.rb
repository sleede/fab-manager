# frozen_string_literal: true

# A ProductStockMovement records a movement of a product's stock.
# Eg. 10 units of item X are added to the stock
class ProductStockMovement < ApplicationRecord
  belongs_to :product

  ALL_STOCK_TYPES = %w[internal external].freeze
  enum stock_type: ALL_STOCK_TYPES.zip(ALL_STOCK_TYPES).to_h

  ALL_REASONS = %w[inward_stock returned cancelled inventory_fix sold missing damaged].freeze
  enum reason: ALL_REASONS.zip(ALL_REASONS).to_h

  validates :stock_type, presence: true
  validates :stock_type, inclusion: { in: ALL_STOCK_TYPES }

  validates :reason, presence: true
  validates :reason, inclusion: { in: ALL_REASONS }

  before_create :set_date

  def set_date
    self.date = DateTime.current
  end
end
