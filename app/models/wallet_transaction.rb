class WalletTransaction < ActiveRecord::Base
  include AmountConcern

  belongs_to :user
  belongs_to :wallet
  belongs_to :reservation
  belongs_to :transactable, polymorphic: true
  has_one :invoice

  validates_inclusion_of :transaction_type, in: %w( credit debit )
  validates :user, :wallet, presence: true
end
