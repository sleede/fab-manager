# frozen_string_literal: true

# user's virtual wallet which can be credited by an admin
# all subsequent user's transactions will charge the wallet, as the default payment mean, if the wallet amount > 0
# if the wallet amount is not sufficient, a secondary payment mean will be requested (card or cash, depending on the login context)
class Wallet < ApplicationRecord
  include AmountConcern

  belongs_to :invoicing_profile
  has_many :wallet_transactions, dependent: :destroy

  validates :invoicing_profile, presence: true

  delegate :user, to: :invoicing_profile

  def credit(amount)
    if amount.is_a?(Numeric) && amount >= 0
      self.amount = (BigDecimal(self.amount.to_s) + BigDecimal(amount.to_s)).to_f
      return save
    end
    false
  end

  def debit(amount)
    if amount.is_a?(Numeric) && amount >= 0
      self.amount = (BigDecimal(self.amount.to_s) - BigDecimal(amount.to_s)).to_f
      return save
    end
    false
  end
end
