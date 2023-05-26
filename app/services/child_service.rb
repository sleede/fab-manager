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

  def self.validate(child, is_valid)
    is_updated = child.update(validated_at: is_valid ? Time.current : nil)
    if is_updated
      if is_valid
        NotificationCenter.call type: 'notify_user_child_is_validated',
                                receiver: child.user,
                                attached_object: child
      else
        NotificationCenter.call type: 'notify_user_child_is_invalidated',
                                receiver: child.user,
                                attached_object: child
      end
    end
    is_updated
  end
end
