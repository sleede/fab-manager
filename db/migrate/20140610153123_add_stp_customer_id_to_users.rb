# frozen_string_literal:true

class AddStpCustomerIdToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :stp_customer_id, :string
    User.reset_column_information
    User.all.each do |user|
      if user.stp_customer_id.blank?
        user.send(:create_stripe_customer)
      end
    end
  end

  def down
    remove_column :users, :stp_customer_id
  end
end
