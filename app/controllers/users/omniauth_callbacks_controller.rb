# frozen_string_literal: true

# Handle authentication actions via OmniAuth (used by SSO providers)
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  require 'sso_logger'
  logger = SsoLogger.new

  active_provider = Rails.configuration.auth_provider
  define_method active_provider.strategy_name do
    logger.info "[Users::OmniauthCallbacksController##{active_provider.strategy_name}] initiated"
    if request.env['omniauth.params'].blank?
      logger.debug 'the user has not provided any authentication token'
      @user = User.from_omniauth(request.env['omniauth.auth'])

      # Here we create the new user or update the existing one with values retrieved from the SSO.

      if @user.id.nil? # => new user (ie. not updating existing)
        logger.debug 'trying to create a new user'
        # If the username is mapped, we just check its uniqueness as it would break the postgresql
        # unique constraint otherwise. If the name is not unique, another unique is generated
        if active_provider.db.sso_fields.include?('user.username')
          logger.debug 'the username was already in use, generating a new one'
          @user.username = generate_unique_username(@user.username)
        end
        # If the email is mapped, we check its uniqueness. If the email is already in use, we mark it as duplicate with an
        # unique random string, because:
        # - if it is the same user, his email will be filled from the SSO when he merge his accounts
        # - if it is not the same user, this will prevent the raise of PG::UniqueViolation
        if active_provider.db.sso_fields.include?('user.email') && email_exists?(@user.email)
          logger.debug 'the email was already in use, marking it as duplicate'
          old_mail = @user.email
          @user.email = "<#{old_mail}>#{Devise.friendly_token}-duplicate"
          flash[:alert] = t('omniauth.email_already_linked_to_another_account_please_input_your_authentication_code', OLD_MAIL: old_mail)
        end
      else # => update of an existing user
        logger.debug "an existing user was found (id=#{@user.id})"
        if username_exists?(@user.username, @user.id)
          logger.debug 'the username was already in use, alerting user'
          flash[:alert] = t('omniauth.your_username_is_already_linked_to_another_account_unable_to_update_it', USERNAME: @user.username)
          @user.username = User.find(@user.id).username
        end

        if email_exists?(@user.email, @user.id)
          logger.debug 'the email was already in use, alerting user'
          flash[:alert] = t('omniauth.your_email_address_is_already_linked_to_another_account_unable_to_update_it', EMAIL: @user.email)
          @user.email = User.find(@user.id).email
        end
      end
      # For users imported from the SSO, we consider the SSO as a source of trust so the email is automatically validated
      @user.confirmed_at = Time.current if active_provider.db.sso_fields.include?('user.email') && !email_exists?(@user.email)

      # We BYPASS THE VALIDATION because, in case of a new user, we want to save him anyway,
      # we'll ask him later to complete his profile (on first login).
      # In case of an existing user, we trust the SSO validation as we want the SSO to have authority on users management and policy.
      logger.debug 'saving the user'
      logger.error "unable to save the user, an error occurred : #{@user.errors.full_messages.join(', ')}" unless @user.save(validate: false)

      logger.debug 'signing-in the user and redirecting'
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
    else
      logger.debug 'the user has provided an authentication token'
      @user = User.find_by(auth_token: request.env['omniauth.params']['auth_token'])

      # Here the user already exists in the database and request to be linked with the SSO
      # so let's update its sso attributes and log him on
      logger.debug "found user id=#{@user.id}"

      begin
        logger.debug 'linking with the omniauth provider'
        @user.link_with_omniauth_provider(request.env['omniauth.auth'])
        logger.debug 'signing-in the user and redirecting'
        sign_in_and_redirect @user, event: :authentication
      rescue DuplicateIndexError
        logger.error 'user already linked'
        redirect_to root_url, alert: t('omniauth.this_account_is_already_linked_to_an_user_of_the_platform', NAME: active_provider.name)
      rescue StandardError => e
        logger.error "an expected error occurred: #{e}"
        raise e
      end
    end
  end

  private

  def username_exists?(username, exclude_id = nil)
    if exclude_id.nil?
      User.where('lower(username) = ?', username&.downcase).size.positive?
    else
      User.where('lower(username) = ?', username&.downcase).where.not(id: exclude_id).size.positive?
    end
  end

  def email_exists?(email, exclude_id = nil)
    if exclude_id.nil?
      User.where('lower(email) = ?', email&.downcase).size.positive?
    else
      User.where('lower(email) = ?', email&.downcase).where.not(id: exclude_id).size.positive?
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
