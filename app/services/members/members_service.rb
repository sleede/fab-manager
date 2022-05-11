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
      @member.errors.add(:group_id, I18n.t('members.unable_to_change_the_group_while_a_subscription_is_running'))
      return false
    end

    if params[:group_id] && params[:group_id].to_i != Group.find_by(slug: 'admins').id && @member.admin?
      # an admin cannot change his group
      @member.errors.add(:group_id, I18n.t('members.admins_cant_change_group'))
      return false
    end

    group_changed = params[:group_id] && @member.group_id != params[:group_id].to_i
    ex_group = @member.group

    user_validation_required = Setting.get('user_validation_required')
    validated_at_changed = false
    if group_changed && user_validation_required
      # here a group change, user must re-validate by admin
      current_proof_of_identity_types = @member.group.proof_of_identity_types
      new_proof_of_identity_types = Group.find(params[:group_id].to_i).proof_of_identity_types
      if @member.validated_at? && !(new_proof_of_identity_types - current_proof_of_identity_types).empty?
        validated_at_changed = true
        @member.validated_at = nil
      end
    end

    not_complete = member.need_completion?
    up_result = member.update(params)

    notify_user_profile_complete(not_complete) if up_result
    member.notify_group_changed(ex_group, validated_at_changed) if group_changed
    up_result
  end

  def create(current_user, params)
    @member.password = password(params)

    # if the user is created by an admin and the authentication is made through an SSO, generate a migration token
    @member.generate_auth_migration_token if current_user.admin? && AuthProvider.active.providable_type != DatabaseProvider.name

    # setup the attached profiles (invoicing & statistics)
    @member.invoicing_profile.email = params[:email]
    @member.invoicing_profile.first_name = params[:profile_attributes][:first_name]
    @member.invoicing_profile.last_name = params[:profile_attributes][:last_name]
    @member.statistic_profile.group_id = params[:group_id]
    @member.statistic_profile.role_id = Role.find_or_create_by!(name: 'member').id

    ActiveRecord::Base.transaction do
      if @member.save
        @member.update_statistic_profile
        @member.generate_subscription_invoice(current_user.id)
        @member.send_confirmation_instructions
        UsersMailer.notify_user_account_created(@member, @member.password).deliver_later
        true
      else
        false
      end
    end
  end

  def merge_from_sso(user)
    merge_result = member.merge_from_sso(user)

    notify_admin_user_merged if merge_result
    merge_result
  end

  def validate(is_valid)
    is_updated = member.update(validated_at: is_valid ? Time.now : nil)
    if is_updated
      if is_valid
        NotificationCenter.call type: 'notify_user_is_validated',
                                receiver: member,
                                attached_object: member
      else
        NotificationCenter.call type: 'notify_user_is_invalidated',
                                receiver: member,
                                attached_object: member
      end
    end
    is_updated
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
