# frozen_string_literal: true

# Provides methods to manage wallets
class WalletService
  def initialize(user: nil, wallet: nil)
    @user = user
    @wallet = wallet
  end

  ## credit an amount to wallet, if credit success then return a wallet transaction and notify to admin
  def credit(amount)
    ActiveRecord::Base.transaction do
      if @wallet.credit(amount)
        transaction = WalletTransaction.new(
          invoicing_profile: @user.invoicing_profile,
          wallet: @wallet,
          transaction_type: 'credit',
          amount: amount
        )
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
        transaction = WalletTransaction.new(
          invoicing_profile: @user&.invoicing_profile,
          wallet: @wallet,
          transaction_type: 'debit',
          amount: amount,
          transactable: transactable
        )

        return transaction if transaction.save
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
    avoir.payment_method = 'wallet'
    avoir.subscription_to_expire = false
    avoir.invoicing_profile_id = wallet_transaction.wallet.user.invoicing_profile.id
    avoir.statistic_profile_id = wallet_transaction.wallet.user.statistic_profile.id
    avoir.total = wallet_transaction.amount * 100.0
    avoir.save!

    ii = InvoiceItem.new
    ii.amount = wallet_transaction.amount * 100.0
    ii.description = I18n.t('invoices.wallet_credit')
    ii.invoice = avoir
    ii.save!
  end
end
