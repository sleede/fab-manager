# frozen_string_literal: true

# OrderActivity is a model for hold activity of order
class OrderActivity < ApplicationRecord
  belongs_to :order

  TYPES = %w[paid payment_failed refunded in_progress ready canceled return note].freeze
  enum activity_type: TYPES.zip(TYPES).to_h

  validates :activity_type, presence: true
end
