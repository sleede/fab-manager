# frozen_string_literal: true

# A single line inside an Order. Can be an article of Order
class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :orderable, polymorphic: true

  validates :orderable, :order_id, :amount, presence: true
end
