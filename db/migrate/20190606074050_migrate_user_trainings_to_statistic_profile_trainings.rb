# frozen_string_literal:true

# Due to RGPD regulations, we cannot save trainings after the deletion of the user's account so we migrate those data
# to the StatisticProfile which is an anonymous ghost of the user's account
class MigrateUserTrainingsToStatisticProfileTrainings < ActiveRecord::Migration[4.2]
  def up
    user_trainings = execute('SELECT * FROM user_trainings')

    user_trainings.each do |ut|
      user = User.find(ut['user_id'])
      # here we use raw sql to prevent the notify_user callback the email the whole DB
      # rubocop:disable Rails/SkipsModelValidations
      spt_id = insert("INSERT INTO statistic_profile_trainings (statistic_profile_id, training_id, created_at, updated_at)
                            VALUES (#{user.statistic_profile.id}, #{ut['training_id']}, '#{ut['created_at']}', '#{Time.current.utc}')")
      # rubocop:enable Rails/SkipsModelValidations

      # update notifications
      execute("UPDATE notifications SET
                   attached_object_type = 'StatisticProfileTraining',
                   attached_object_id = #{spt_id},
                   updated_at = '#{Time.current.utc}'
                   WHERE attached_object_id = #{ut['id']} AND attached_object_type = 'UserTraining'")
    end
  end

  def down
    StatisticProfileTraining.all.each do |spt|
      statistic_profile = StatisticProfile.find(spt.statistic_profile_id)
      ut_id = execute("INSERT INTO user_trainings (user_id, training_id, created_at, updated_at)
                           VALUES (#{statistic_profile.user_id}, #{spt.training_id}, '#{spt.created_at.utc}', '#{Time.current.utc}')")
      execute("UPDATE notifications SET
                   attached_object_type = 'UserTraining',
                   attached_object_id = #{ut_id},
                   updated_at = '#{Time.current.utc}'
                   WHERE attached_object_id = #{spt.id} AND attached_object_type = 'StatisticProfileTraining'")
    end
  end
end
