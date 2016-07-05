class Wallet < ActiveRecord::Base
  include AmountConcern

  belongs_to :user
  has_many :wallet_transactions, dependent: :destroy

  validates :user, presence: true

  def credit(amount)
    if amount.is_a?(Numeric) and amount >= 0
      self.amount += amount
      return save
    end
    false
  end

  def debit(amount)
    if amount.is_a?(Numeric) and amount >= 0
      self.amount -= amount
      return save
    end
    false
  end
end
