class WalletTransaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :wallet
  belongs_to :reservation
  belongs_to :transactable, polymorphic: true
end
