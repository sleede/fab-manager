# frozen_string_literal:true

class MigrateProjetToStatisticProfile < ActiveRecord::Migration[4.2]
  def up
    Project.all.each do |p|
      author = User.find(p.author_id)
      p.update_column(
        'author_statistic_profile_id', author.statistic_profile.id
      )
    end
  end

  def down
    Project.all.each do |p|
      statistic_profile = User.find(p.author_statistic_profile_id)
      p.update_column(
        'author_id', statistic_profile.user_id
      )
    end
  end
end
