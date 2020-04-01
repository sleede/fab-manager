# frozen_string_literal:true

class RenameExpiredAtToExpirationDateFromSubscription < ActiveRecord::Migration[4.2]
  def up
    rename_column :subscriptions, :expired_at, :expiration_date
  end

  def down
    rename_column :subscriptions, :expiration_date, :expired_at
  end
end
