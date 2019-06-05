class MigrateSubscriptionToStatisticProfile < ActiveRecord::Migration
  def up
    Subscription.all.each do |s|
      user = User.find(s.user_id)
      s.update_column(
        'statistic_profile_id', user.statistic_profile.id
      )
    end
  end

  def down
    Subscription.all.each do |s|
      statistic_profile = User.find(s.statistic_profile_id)
      s.update_column(
        'user_id', statistic_profile.user_id
      )
    end
  end
end
