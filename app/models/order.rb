# frozen_string_literal: true

# Order is a model for the user hold information of order
class Order < ApplicationRecord
  belongs_to :statistic_profile
  has_many :order_items, dependent: :destroy

  ALL_STATES = %w[cart].freeze
  enum state: ALL_STATES.zip(ALL_STATES).to_h

  PAYMENT_STATES = %w[paid failed].freeze
  enum payment_state: PAYMENT_STATES.zip(PAYMENT_STATES).to_h

  validates :token, :state, presence: true
end
