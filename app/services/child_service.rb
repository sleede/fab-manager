# frozen_string_literal: true

# ChildService
class ChildService
  def self.create(child)
    if child.save
      NotificationCenter.call type: 'notify_admin_child_created',
                              receiver: User.admins_and_managers,
                              attached_object: child
      return true
    end
    false
  end

  def self.update(child, child_params)
    child.update(child_params)
  end
end
