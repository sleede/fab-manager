class ChangeStartAtToExpiredAtFromSubscription < ActiveRecord::Migration
  def change
    remove_column :subscriptions, :start_at, :datetime
    add_column :subscriptions, :expired_at, :datetime

    Subscription.all.each do |s|
      if s.respond_to? :expired_at and !s.expired_at?
        if s.plan.interval == 'month'
          s.update_columns(expired_at: s.created_at + 1.month)
        else
          s.update_columns(expired_at: s.created_at + 1.year)
        end
      end
    end
  end
end
