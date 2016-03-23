class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.belongs_to :plan, index: true
      t.belongs_to :user, index: true
      t.string :stp_subscription_id

      t.timestamps
    end
  end
end
