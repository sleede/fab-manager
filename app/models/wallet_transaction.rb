class WalletTransaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :wallet
  belongs_to :reservation
  belongs_to :transactable, polymorphic: true

  validates_inclusion_of :transaction_type, in: %w( credit debit )
end
