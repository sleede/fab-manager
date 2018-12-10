class RenameExpiredAtToExpirationDateFromSubscription < ActiveRecord::Migration
  def up
    rename_column :subscriptions, :expired_at, :expiration_date
  end

  def down
    rename_column :subscriptions, :expiration_date, :expired_at
  end
end
