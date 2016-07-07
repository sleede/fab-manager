class WalletService
  def initialize(user: nil, wallet: nil)
    @user = user
    @wallet = wallet
  end

  def credit(amount)
    if @wallet.credit(amount)
      transaction = WalletTransaction.create(user: @user, wallet: @wallet, transaction_type: 'credit', amount: amount)

      NotificationCenter.call type: 'notify_user_wallet_is_credited',
                              receiver: @wallet.user,
                              attached_object: transaction
      NotificationCenter.call type: 'notify_admin_user_wallet_is_credited',
                              receiver: User.admins,
                              attached_object: transaction
      return true
    end
    return false
  end

  def debit(amount, transactable)
    if @wallet.debit(amount)
      WalletTransaction.create(user: @user, wallet: @wallet, transaction_type: 'debit', amount: amount, transactable: transactable)
      return true
    end
    return false
  end
end
