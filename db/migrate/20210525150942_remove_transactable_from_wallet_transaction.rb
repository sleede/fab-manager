# frozen_string_literal: true

# Following the scheme of the previous migrations, we cannot store anymore a single object as "the bought item"
# because wa want to be able to buy multiple items at the same time.
# Previously WalletTransaction was saving the item bought using the wallet in transactable columns (polymorphic).
# This was limiting to one item only, was redundant with (Invoice|PaymentSchedule).wallet_transaction_id, and anyway
# this data was not used anywhere in the application so we remove it.
class RemoveTransactableFromWalletTransaction < ActiveRecord::Migration[5.2]
  def change
    remove_reference :wallet_transactions, :transactable, polymorphic: true
  end
end
