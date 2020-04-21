# frozen_string_literal: true

# helpers for managing users with special roles
class UserService
  def self.create_partner(params)
    generated_password = Devise.friendly_token.first(8)
    group_id = Group.first.id
    user = User.new(
      email: params[:email],
      username: "#{params[:first_name]}#{params[:last_name]}".parameterize,
      password: generated_password,
      password_confirmation: generated_password,
      group_id: group_id
    )
    user.build_profile(
      first_name: params[:first_name],
      last_name: params[:last_name],
      phone: '0000000000'
    )
    user.build_statistic_profile(
      gender: true,
      birthday: DateTime.current
    )

    saved = user.save
    if saved
      user.remove_role :member
      user.add_role :partner
    end
    { saved: saved, user: user }
  end

  def self.create_admin(params)
    generated_password = Devise.friendly_token.first(8)
    admin = User.new(params.merge(password: generated_password))
    admin.send :set_slug

    # we associate the admin group to prevent linking any other 'normal' group (which won't be deletable afterwards)
    admin.group = Group.find_by(slug: 'admins')

    # if the authentication is made through an SSO, generate a migration token
    admin.generate_auth_migration_token unless AuthProvider.active.providable_type == DatabaseProvider.name

    saved = admin.save
    if saved
      admin.send_confirmation_instructions
      admin.add_role(:admin)
      admin.remove_role(:member)
      UsersMailer.delay.notify_user_account_created(admin, generated_password)
    end
    { saved: saved, user: admin }
  end

  def self.create_manager(params)
    generated_password = Devise.friendly_token.first(8)
    manager = User.new(params.merge(password: generated_password))
    manager.send :set_slug

    saved = manager.save
    if saved
      manager.send_confirmation_instructions
      manager.add_role(:admin)
      manager.remove_role(:member)
      UsersMailer.delay.notify_user_account_created(manager, generated_password)
    end
    { saved: saved, user: manager }
  end
end
