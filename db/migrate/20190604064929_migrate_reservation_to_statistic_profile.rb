# frozen_string_literal:true

class MigrateReservationToStatisticProfile < ActiveRecord::Migration[4.2]
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
