# frozen_string_literal:true

# From this migration, we split the user's profile into multiple tables:
# StatisticProfile is intended to keep anonymous statisttical data about the user after his account was deleted
class MigrateProfileToStatisticProfile < ActiveRecord::Migration[4.2]
  def up
    User.all.each do |u|
      p = u.profile
      Rails.logger.warn "User #{u.id} has no profile" and next unless p

      StatisticProfile.create!(
        user: u,
        group: u.group,
        role: u.roles.first,
        gender: p.gender,
        birthday: p.birthday,
        created_at: u.created_at
      )
    end
  end

  def down
    StatisticProfile.all.each do |sp|
      p = sp.user.profile
      Rails.logger.warn "User #{sp.user_id} has no profile" and next unless p

      p.update(
        gender: sp.gender,
        birthday: sp.birthday
      )
    end
  end
end
