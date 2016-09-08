class WalletService
  def initialize(user: nil, wallet: nil)
    @user = user
    @wallet = wallet
  end

  ## credit an amount to wallet, if credit success then return a wallet transaction and notify to admin
  def credit(amount)
    ActiveRecord::Base.transaction do
      if @wallet.credit(amount)
        transaction = WalletTransaction.new(user: @user, wallet: @wallet, transaction_type: 'credit', amount: amount)
        if transaction.save
          NotificationCenter.call type: 'notify_user_wallet_is_credited',
                                  receiver: @wallet.user,
                                  attached_object: transaction
          NotificationCenter.call type: 'notify_admin_user_wallet_is_credited',
                                  receiver: User.admins,
                                  attached_object: transaction
          return transaction
        end
      end
      raise ActiveRecord::Rollback
    end
    return false
  end

  ## debit an amount to wallet, if debit success then return a wallet transaction
  def debit(amount, transactable)
    ActiveRecord::Base.transaction do
      if @wallet.debit(amount)
        transaction = WalletTransaction.new(user: @user, wallet: @wallet, transaction_type: 'debit', amount: amount, transactable: transactable)
        if transaction.save
          return transaction
        end
      end
      raise ActiveRecord::Rollback
    end
    return false
  end
end
