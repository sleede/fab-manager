
class MembersProcessor

  attr_accessor :member

  def initialize(member)
    @member = member
  end

  def update(params)
    not_complete = self.member.need_completion?
    up_result = self.member.update(params)
    if up_result
      notify_user_profile_complete(not_complete)
    end
    up_result
  end

  def merge_from_sso(user)
    merge_result = self.member.merge_from_sso(user)
    if merge_result
      notify_admin_user_merged
    end
    merge_result
  end

  private
  def notify_user_profile_complete(previous_state)
    if previous_state and not self.member.need_completion?
      NotificationCenter.call type: :notify_user_profile_complete,
                              receiver: self.member,
                              attached_object: self.member
      NotificationCenter.call type: :notify_admin_profile_complete,
                              receiver: User.admins,
                              attached_object: self.member
    end
  end

  def notify_admin_user_merged
    NotificationCenter.call type: :notify_admin_user_merged,
                            receiver: User.admins,
                            attached_object: self.member
  end

end