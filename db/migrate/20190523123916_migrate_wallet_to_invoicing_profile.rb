# frozen_string_literal:true

class MigrateWalletToInvoicingProfile < ActiveRecord::Migration[4.2]
  def up
    Wallet.all.each do |w|
      user = User.find(w.user_id)
      w.update_attributes(
        invoicing_profile_id: user.invoicing_profile.id
      )
    end
    WalletTransaction.all.each do |wt|
      user = User.find(wt.user_id)
      wt.update_attributes(
        invoicing_profile_id: user.invoicing_profile.id
      )
    end
  end

  def down
    Wallet.all.each do |w|
      invoicing_profile = User.find(w.invoicing_profile_id)
      w.update_attributes(
        user_id: invoicing_profile.user_id
      )
    end
    WalletTransaction.all.each do |wt|
      invoicing_profile = User.find(wt.invoicing_profile_id)
      wt.update_attributes(
        user_id: invoicing_profile.user_id
      )
    end
  end
end
