# frozen_string_literal: true

# Provides methods for Groups
class GroupService
  def self.list(filters = {})
    groups = Group.where(nil)

    if filters[:disabled].present?
      state = filters[:disabled] == 'false' ? [nil, false] : true
      groups = groups.where(disabled: state)
    end

    groups
  end
end
