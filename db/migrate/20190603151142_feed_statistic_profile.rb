class FeedStatisticProfile < ActiveRecord::Migration
  def change
    User.all.each do |u|
      p = u.profile
      puts "WARNING: User #{u.id} has no profile" and next unless p

      StatisticProfile.create!(
        user: u,
        group: u.group,
        gender: p.gender,
        birthday: p.birthday
      )
    end
  end
end
