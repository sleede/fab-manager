class MigrateUserTrainingsToStatisticProfileTrainings < ActiveRecord::Migration
  def up
    user_trainings = execute('SELECT * FROM user_trainings')

    user_trainings.each do |ut|
      user = User.find(ut['user_id'])
      StatisticProfileTraining.create!(
        statistic_profile_id: user.statistic_profile.id,
        training_id: ut['training_id'],
        created_at: ut['created_at']
      )
    end
  end

  def down
    StatisticProfileTraining.all.each do |spt|
      statistic_profile = StatisticProfile.find(spt.statistic_profile_id)
      execute("INSERT INTO user_trainings (user_id, training_id, created_at, updated_at)
                   VALUES (#{statistic_profile.user_id}, #{spt.training_id}, '#{spt.created_at.utc}', '#{DateTime.now.utc}')")
    end
  end
end
