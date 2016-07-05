class WalletService
  def initialize(user: nil, wallet: nil)
    @user = user
    @wallet = wallet
  end

  def credit(amount)
    if @wallet.credit(amount)
      WalletTransaction.create(user: @user, wallet: @wallet, transaction_type: 'credit', amount: amount)
      return true
    end
  end
end
