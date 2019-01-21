# frozen_string_literal: true

# Provides helper methods for User actions
class Members::MembersService

  attr_accessor :member

  def initialize(member)
    @member = member
  end

  def update(params)

    if params[:group_id] && @member.group_id != params[:group_id].to_i && !@member.subscribed_plan.nil?
      # here a group change is requested but unprocessable, handle the exception
      @member.errors[:group_id] = I18n.t('members.unable_to_change_the_group_while_a_subscription_is_running')
      return false
    end

    not_complete = member.need_completion?
    up_result = member.update(params)

    notify_user_profile_complete(not_complete) if up_result
    up_result
  end

  def create(current_user, params)
    @member.password = password(params)

    # if the user is created by an admin and the authentication is made through an SSO, generate a migration token
    @member.generate_auth_migration_token if current_user.admin? && AuthProvider.active.providable_type != DatabaseProvider.name

    if @member.save
      @member.generate_subscription_invoice
      @member.send_confirmation_instructions
      UsersMailer.delay.notify_user_account_created(@member, @member.password)
      true
    else
      false
    end
  end

  def merge_from_sso(user)
    merge_result = member.merge_from_sso(user)

    notify_admin_user_merged if merge_result
    merge_result
  end

  private

  def notify_user_profile_complete(previous_state)
    return unless previous_state && !member.need_completion?

    NotificationCenter.call type: :notify_user_profile_complete,
                            receiver: member,
                            attached_object: member
    NotificationCenter.call type: :notify_admin_profile_complete,
                            receiver: User.admins,
                            attached_object: member
  end

  def notify_admin_user_merged
    NotificationCenter.call type: :notify_admin_user_merged,
                            receiver: User.admins,
                            attached_object: member
  end

  def password(params)
    if !params[:password] && !params[:password_confirmation]
      Devise.friendly_token.first(8)
    else
      params[:password]
    end
  end

end
