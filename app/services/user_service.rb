# frozen_string_literal: true

# helpers for managing users with special roles
class UserService
  class << self
    def create_partner(params)
      generated_password = SecurePassword.generate
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
        birthday: Time.current
      )

      saved = user.save
      if saved
        user.remove_role :member
        user.add_role :partner
      end
      { saved: saved, user: user }
    end

    def create_admin(params)
      generated_password = SecurePassword.generate
      admin = User.new(params.merge(password: generated_password, validated_at: Time.current))
      admin.send :set_slug

      # if the authentication is made through an SSO, generate a migration token
      admin.generate_auth_migration_token unless AuthProvider.active.providable_type == DatabaseProvider.name

      saved = admin.save
      if saved
        admin.send_confirmation_instructions
        admin.add_role(:admin)
        admin.remove_role(:member)
        UsersMailer.notify_user_account_created(admin, generated_password).deliver_later
      end
      { saved: saved, user: admin }
    end

    def create_manager(params)
      generated_password = SecurePassword.generate
      manager = User.new(params.merge(password: generated_password))
      manager.send :set_slug

      saved = manager.save
      if saved
        manager.send_confirmation_instructions
        manager.add_role(:manager)
        manager.remove_role(:member)
        UsersMailer.notify_user_account_created(manager, generated_password).deliver_later
      end
      { saved: saved, user: manager }
    end
  end
end
