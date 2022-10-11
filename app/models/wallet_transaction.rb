# frozen_string_literal: true

# track of all transactions payed using the given wallet
class WalletTransaction < ApplicationRecord
  include AmountConcern

  belongs_to :invoicing_profile
  belongs_to :wallet
  belongs_to :reservation
  # what was paid with the wallet
  has_one :invoice, dependent: :nullify
  has_one :payment_schedule, dependent: :nullify
  # how the wallet was credited
  has_one :invoice_item, as: :object, dependent: :destroy

  validates :transaction_type, inclusion: { in: %w[credit debit] }
  validates :invoicing_profile, :wallet, presence: true

  delegate :user, to: :invoicing_profile

  def original_invoice
    invoice_item.invoice
  end
end
