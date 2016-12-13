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
    false
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
    false
  end

  ## create a refund invoice associated with the given wallet transaction
  def create_avoir(wallet_transaction, avoir_date, description)
    avoir = Avoir.new
    avoir.type = 'Avoir'
    avoir.invoiced = wallet_transaction
    avoir.avoir_date = avoir_date
    avoir.created_at = avoir_date
    avoir.description = description
    avoir.avoir_mode = 'wallet'
    avoir.subscription_to_expire = false
    avoir.user_id = wallet_transaction.wallet.user_id
    avoir.total = wallet_transaction.amount * 100.0
    avoir.save!

    ii = InvoiceItem.new
    ii.amount = wallet_transaction.amount * 100.0
    ii.description = I18n.t('invoices.wallet_credit')
    ii.invoice = avoir
    ii.save!
  end
end
