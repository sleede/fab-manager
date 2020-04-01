# frozen_string_literal:true

class RemoveStatisticColumns < ActiveRecord::Migration[4.2]
  def change
    remove_column :profiles, :gender, :boolean
    remove_column :profiles, :birthday, :date
    remove_column :reservations, :user_id
    remove_column :subscriptions, :user_id
    remove_column :projects, :author_id
  end
end
