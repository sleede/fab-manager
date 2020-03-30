# frozen_string_literal:true

class AddIsAllowNewsletterToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_allow_newsletter, :boolean
  end
end
