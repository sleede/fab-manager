class Wallet < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true
  validates_numericality_of :amount, greater_than_or_equal_to: 0

  def amount=(amount)
    write_attribute(:amount, amount.to_i * 100)
  end

  def amount
    read_attribute(:amount) / 100.0
  end

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
