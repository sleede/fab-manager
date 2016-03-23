class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user
        scope.includes(:project_image, :machines, :users)
                           .where("state = 'published' OR (state = 'draft' AND (author_id = ? OR users.id = ?))", user.id, user.id)
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
    user.is_admin? or record.author == user or record.users.include?(user)
  end

  def destroy?
    user.is_admin? or record.author == user
  end
end
