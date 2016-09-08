class AddIsAllowNewsletterToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_allow_newsletter, :boolean
  end
end
