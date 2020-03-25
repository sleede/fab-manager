# frozen_string_literal: true

# track of all transactions payed using the given wallet
class WalletTransaction < ApplicationRecord
  include AmountConcern

  belongs_to :invoicing_profile
  belongs_to :wallet
  belongs_to :reservation
  belongs_to :transactable, polymorphic: true
  has_one :invoice

  validates_inclusion_of :transaction_type, in: %w[credit debit]
  validates :invoicing_profile, :wallet, presence: true

  def user
    invoicing_profile.user
  end
end
