# frozen_string_literal: true

# Provides helper methods for User actions
class Members::MembersService
  attr_accessor :member

  def initialize(member)
    @member = member
  end

  def update(params)
    if subscriber_group_change?(params)
      # here a group change is requested but unprocessable, handle the exception
      @member.errors.add(:group_id, I18n.t('members.unable_to_change_the_group_while_a_subscription_is_running'))
      return false
    end

    if admin_group_change?(params)
      # an admin cannot change his group
      @member.errors.add(:group_id, I18n.t('members.admins_cant_change_group'))
      return false
    end

    group_changed = user_group_change?(params)
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

    Members::MembersService.handle_organization(params)

    not_complete = member.need_completion?
    up_result = member.update(params)

    notify_user_profile_complete(not_complete) if up_result
    member.notify_group_changed(ex_group, validated_at_changed) if group_changed && !ex_group.nil?
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
    is_updated = member.update(validated_at: is_valid ? DateTime.current : nil)
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

  def self.handle_organization(params)
    return params unless params[:invoicing_profile_attributes] && params[:invoicing_profile_attributes][:organization]

    if params[:invoicing_profile_attributes][:organization] == 'false'
      params[:invoicing_profile_attributes].reject! { |p| %w[organization_attributes organization].include?(p) }
    else
      params[:invoicing_profile_attributes].reject! { |p| p == 'organization' }
    end

    params
  end

  def self.last_registered(limit)
    query = User.active.with_role(:member)
                .includes(:statistic_profile, profile: [:user_avatar])
                .where('is_allow_contact = true AND confirmed_at IS NOT NULL')
                .order('created_at desc')
                .limit(limit)

    # remove unmerged profiles from list
    members = query.to_a
    members.delete_if(&:need_completion?)

    [query, members]
  end

  def update_role(new_role, new_group_id = Group.first.id)
    # do nothing if the role does not change
    return if new_role == @member.role

    # update role
    ex_role = @member.role.to_sym
    @member.remove_role ex_role
    @member.add_role new_role

    # if the new role is 'admin', then change the group to the admins group, otherwise to change to the provided group
    group_id = new_role == 'admin' ? Group.find_by(slug: 'admins').id : new_group_id
    @member.update(group_id: group_id)

    # notify
    NotificationCenter.call type: 'notify_user_role_update',
                            receiver: @member,
                            attached_object: @member

    NotificationCenter.call type: 'notify_admins_role_update',
                            receiver: User.admins_and_managers,
                            attached_object: @member,
                            meta_data: { ex_role: ex_role }
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
      SecurePassword.generate
    else
      params[:password]
    end
  end

  def subscriber_group_change?(params)
    params[:group_id] && @member.group_id != params[:group_id].to_i && !@member.subscribed_plan.nil?
  end

  def admin_group_change?(params)
    params[:group_id] && params[:group_id].to_i != Group.find_by(slug: 'admins').id && @member.admin?
  end

  def user_group_change?(params)
    @member.group_id && params[:group_id] && @member.group_id != params[:group_id].to_i
  end
end
