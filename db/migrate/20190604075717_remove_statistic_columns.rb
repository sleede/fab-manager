class RemoveStatisticColumns < ActiveRecord::Migration
  def change
    remove_column :profiles, :gender, :boolean
    remove_column :profiles, :birthday, :date
    remove_column :reservations, :user_id
    remove_column :subscriptions, :user_id
  end
end
