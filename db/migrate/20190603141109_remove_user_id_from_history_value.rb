class RemoveUserIdFromHistoryValue < ActiveRecord::Migration
  def change
    remove_reference :history_values, :user, index: true, foreign_key: true
  end
end
