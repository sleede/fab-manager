# frozen_string_literal: true

# Provides helper methods for User actions
class Members::MembersService
  attr_accessor :member

  def initialize(member)
    @member = member
  end

  def update(params, operator, current_password = nil)
    group_changed, target_group = handle_group_change(params, operator)
    return false if group_changed == :error

    ex_group = @member.group

    user_validation_required = Setting.get('user_validation_required')
    validated_at_changed = false
    if group_changed && user_validation_required && target_group
      current_types = ex_group&.supporting_document_types || []
      new_types = target_group.supporting_document_types
      if @member.validated_at? && !(new_types - current_types).empty?
        validated_at_changed = true
        @member.validated_at = nil
        @member.supporting_documents_reminder_sent_at = nil
      end
    end

    return false unless handle_password(params, operator, current_password)

    Members::MembersService.handle_organization(params)

    not_complete = member.need_completion?
    up_result = member.update(params)

    notify_user_profile_complete(not_complete) if up_result
    member.notify_group_changed(ex_group, validated_at_changed) if up_result && group_changed && !ex_group.nil?
    up_result
  end

  def create(current_user, params)
    @member.password = password(params)

    # if the authentication is made through an SSO, generate a migration token
    @member.generate_auth_migration_token if AuthProvider.active.providable_type != DatabaseProvider.name

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
    is_updated = member.update(validated_at: is_valid ? Time.current : nil)
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

  def self.last_registered(limit = 10)
    limit = [limit.to_i, 10].min
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

    @member.update(group_id: new_group_id)

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

  def handle_group_change(params, operator)
    return [false, nil] unless params.key?(:group_id) || params.key?('group_id')

    raw_group_id = params[:group_id] || params['group_id']
    unless valid_group_id_param?(raw_group_id)
      @member.errors.add(:group_id, :invalid)
      return [:error, nil]
    end

    new_group_id = raw_group_id.to_i
    return [false, nil] if @member.group_id == new_group_id

    if @member.subscribed_plan.present?
      @member.errors.add(:group_id, I18n.t('members.unable_to_change_the_group_while_a_subscription_is_running'))
      return [:error, nil]
    end

    target_group = Group.find_by(id: new_group_id)
    return [:error, nil] unless allowed_to_switch_to_group?(target_group, operator)

    [true, target_group]
  end

  def valid_group_id_param?(raw_group_id)
    (raw_group_id.is_a?(Integer) && raw_group_id.positive?) ||
      (raw_group_id.is_a?(String) && raw_group_id.strip =~ /\A\d+\z/ && raw_group_id.to_i.positive?)
  end

  def allowed_to_switch_to_group?(target_group, operator)
    if target_group.nil?
      @member.errors.add(:group_id, :invalid)
      return false
    end

    return true if operator&.privileged?

    unless Setting.get('user_change_group') == true
      @member.errors.add(:group_id, I18n.t('members.unable_to_change_group_disabled', default: 'Changing group is not allowed'))
      return false
    end

    if target_group.disabled?
      @member.errors.add(:group_id, :invalid)
      return false
    end

    true
  end

  def handle_password(params, operator, current_password = nil)
    current_password ||= params[:current_password]

    if params[:password].blank? && params[:password_confirmation].blank?
      params.delete(:password)
      params.delete('password')
      params.delete(:password_confirmation)
      params.delete('password_confirmation')
      return true
    end

    if @member.provider.present? && @member.provider != 'DatabaseProvider'
      @member.errors.add(:password, I18n.t('members.cannot_change_sso_password', default: 'Password cannot be changed for SSO accounts'))
      return false
    end

    if params[:password].blank?
      @member.errors.add(:password, :blank)
      return false
    end

    if params[:password_confirmation].blank?
      @member.errors.add(:password_confirmation, :blank)
      return false
    end

    if params[:password] != params[:password_confirmation]
      @member.errors.add(:password_confirmation, :confirmation, attribute: User.human_attribute_name(:password))
      return false
    end

    return true if operator&.privileged? && operator.id != @member.id

    if current_password.blank?
      @member.errors.add(:current_password, :blank)
      return false
    end

    unless @member.valid_password?(current_password)
      @member.errors.add(:current_password, :invalid)
      return false
    end

    true
  end
end
