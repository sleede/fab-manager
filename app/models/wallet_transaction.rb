# frozen_string_literal: true

# track of all transactions payed using the given wallet
class WalletTransaction < ApplicationRecord
  include AmountConcern

  belongs_to :invoicing_profile
  belongs_to :wallet
  belongs_to :reservation
  # what was paid with the wallet
  has_one :invoice
  has_one :payment_schedule
  # how the wallet was credited
  has_one :invoice_item, as: :object, dependent: :destroy

  validates_inclusion_of :transaction_type, in: %w[credit debit]
  validates :invoicing_profile, :wallet, presence: true

  def user
    invoicing_profile.user
  end
end
