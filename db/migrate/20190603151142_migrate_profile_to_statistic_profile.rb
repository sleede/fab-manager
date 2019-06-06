class MigrateProfileToStatisticProfile < ActiveRecord::Migration
  def up
    User.all.each do |u|
      p = u.profile
      puts "WARNING: User #{u.id} has no profile" and next unless p

      StatisticProfile.create!(
        user: u,
        group: u.group,
        role: u.roles.first,
        gender: p.gender,
        birthday: p.birthday
      )
    end
  end

  def down
    StatisticProfile.all.each do |sp|
      p = sp.user.profile
      puts "WARNING: User #{sp.user_id} has no profile" and next unless p

      p.update_attributes(
        gender: sp.gender,
        birthday: sp.birthday
      )
    end
  end
end
