# frozen_string_literal: true

# Order is a model for the user hold information of order
class Order < ApplicationRecord
  belongs_to :statistic_profile
  belongs_to :operator_profile, class_name: 'InvoicingProfile'
  has_many :order_items, dependent: :destroy

  ALL_STATES = %w[cart in_progress ready canceled return].freeze
  enum state: ALL_STATES.zip(ALL_STATES).to_h

  PAYMENT_STATES = %w[paid failed refunded].freeze
  enum payment_state: PAYMENT_STATES.zip(PAYMENT_STATES).to_h

  validates :token, :state, presence: true

  def set_wallet_transaction(amount, transaction_id)
    self.wallet_amount = amount
    self.wallet_transaction_id = transaction_id
  end
end
