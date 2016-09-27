class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  active_provider = AuthProvider.active
  define_method active_provider.strategy_name do
    if request.env['omniauth.params'].blank?
      @user = User.from_omniauth(request.env['omniauth.auth'])

      # Here we create the new user or update the existing one with values retrieved from the SSO.

      if @user.id.nil? # => new user (ie. not updating existing)
        # If the username is mapped, we just check its uniqueness as it would break the postgresql
        # unique contraint otherwise. If the name is not unique, another unique is generated
        if active_provider.sso_fields.include?('user.username')
          @user.username = generate_unique_username(@user.username)
        end
        # If the email is mapped, we check its uniqueness. If the email is already in use, we mark it as duplicate with an
        # unique random string, because:
        # - if it is the same user, his email will be filled from the SSO when he merge his accounts
        # - if it is not the same user, this will prevent the raise of PG::UniqueViolation
        if active_provider.sso_fields.include?('user.email') and email_exists?(@user.email)
          old_mail = @user.email
          @user.email = "<#{old_mail}>#{Devise.friendly_token}-duplicate"
          flash[:alert] = t('omniauth.email_already_linked_to_another_account_please_input_your_authentication_code', OLD_MAIL: old_mail)
        end
      else # => update of an existing user
        if username_exists?(@user.username, @user.id)
          flash[:alert] = t('omniauth.your_username_is_already_linked_to_another_account_unable_to_update_it', USERNAME: @user.username)
          @user.username = User.find(@user.id).username
        end

        if email_exists?(@user.email, @user.id)
          flash[:alert] = t('omniauth.your_email_address_is_already_linked_to_another_account_unable_to_update_it', EMAIL: @user.email)
          @user.email = User.find(@user.id).email
        end
      end

      # We BYPASS THE VALIDATION because, in case of a new user, we want to save him anyway, we'll ask him later to complete his profile (on first login).
      # In case of an existing user, we trust the SSO validation as we want the SSO to have authority on users management and policy.
      @user.save(:validate => false)
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
    else
      @user = User.find_by(auth_token: request.env['omniauth.params']['auth_token'])

      # Here the user already exists in the database and request to be linked with the SSO
      # so let's update its sso attributes and log him on

      begin
        @user.link_with_omniauth_provider(request.env['omniauth.auth'])
        sign_in_and_redirect @user, :event => :authentication
      rescue DuplicateIndexError
        redirect_to root_url, alert: t('omniauth.this_account_is_already_linked_to_an_user_of_the_platform', NAME: active_provider.name)
      end
    end

  end

  private
  def username_exists?(username, exclude_id = nil)
    if exclude_id.nil?
      User.where(username: username).size > 0
    else
      User.where(username: username).where.not(id: exclude_id).size > 0
    end
  end

  def email_exists?(email, exclude_id = nil)
    if exclude_id.nil?
      User.where(email: email).size > 0
    else
      User.where(email: email).where.not(id: exclude_id).size > 0
    end
  end

  def generate_unique_username(username)
    generated = username
    i = 1000
    while username_exists?(generated)
      generated = username + rand(1..i).to_s
      i += 10
    end
    generated
  end
end