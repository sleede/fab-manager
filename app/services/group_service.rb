# frozen_string_literal: true

# Provides methods for Groups
class GroupService
  def self.list(operator, filters = {})
    groups = if operator&.admin?
               Group.where(nil)
             else
               Group.where.not(slug: 'admins')
             end

    if filters[:disabled].present?
      state = filters[:disabled] == 'false' ? [nil, false] : true
      groups = groups.where(disabled: state)
    end

    groups
  end
end
