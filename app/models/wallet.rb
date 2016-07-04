class Wallet < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true
  validates_numericality_of :amount, greater_than_or_equal_to: 0

  def credit(amount)
    self.amount += amount
    save
  end

  def debit(amount)
    self.amount -= amount
    save
  end
end
