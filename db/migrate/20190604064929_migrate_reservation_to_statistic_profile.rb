class MigrateReservationToStatisticProfile < ActiveRecord::Migration
  def up
    Reservation.all.each do |r|
      user = User.find(r.user_id)
      r.update_column(
        'statistic_profile_id', user.statistic_profile.id
      )
    end
  end

  def down
    Reservation.all.each do |r|
      statistic_profile = User.find(r.statistic_profile_id)
      r.update_column(
        'user_id', statistic_profile.user_id
      )
    end
  end
end
