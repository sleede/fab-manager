class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user
        statistic_profile = StatisticProfile.find_by(user_id: user.id)
        scope.includes(:project_image, :machines, :users)
             .where("state = 'published' OR (state = 'draft' AND (author_statistic_profile_id = ? OR users.id = ?))", statistic_profile.id, user.id)
             .references(:users)
             .order(created_at: :desc)
      else
        scope.includes(:project_image, :machines, :users)
             .where("state = 'published'")
             .order(created_at: :desc)
      end
    end
  end

  def update?
    user.admin? or record.author.user_id == user.id or record.users.include?(user)
  end

  def destroy?
    user.admin? or record.author.user_id == user
  end
end
