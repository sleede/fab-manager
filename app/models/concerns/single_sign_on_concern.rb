# frozen_string_literal: true

# Add single sign on functionalities to the user model
module SingleSignOnConcern
  extend ActiveSupport::Concern
  require 'sso_logger'

  included do
    # enable OmniAuth authentication only if needed
    devise :omniauthable, omniauth_providers: [Rails.configuration.auth_provider.strategy_name.to_sym] unless
      Rails.configuration.auth_provider.providable_type == 'DatabaseProvider'

    ## Retrieve the requested data in the User and user's Profile tables
    ## @param sso_mapping {String} must be of form 'user._field_' or 'profile._field_'. Eg. 'user.email'
    def get_data_from_sso_mapping(sso_mapping)
      service = UserGetterService.new(self)
      service.read_attribute(sso_mapping)
    end

    ## Set some data on the current user, according to the sso_key given
    ## @param sso_mapping {String} must be of form 'user._field_' or 'profile._field_'. Eg. 'user.email'
    ## @param data {*} the data to put in the given key. Eg. 'user@example.com'
    def set_data_from_sso_mapping(sso_mapping, data)
      return if data.nil? || data.blank?

      service = UserSetterService.new(self)
      service.assign_attibute(sso_mapping, data)

      return if mapped_from_sso&.include?(sso_mapping)

      self.mapped_from_sso = [mapped_from_sso, sso_mapping].compact.join(',')
    end

    ## used to allow the migration of existing users between authentication providers
    def generate_auth_migration_token
      update(auth_token: Devise.friendly_token)
    end

    ## link the current user to the given provider (omniauth attributes hash)
    ## and remove the auth_token to mark his account as "migrated"
    def link_with_omniauth_provider(auth)
      active_provider = Rails.configuration.auth_provider
      raise SecurityError, 'The identity provider does not match the activated one' if active_provider.strategy_name != auth.provider

      if User.where(provider: auth.provider, uid: auth.uid).size.positive?
        raise DuplicateIndexError, "This #{active_provider.name} account is already linked to an existing user"
      end

      update(provider: auth.provider, uid: auth.uid, auth_token: nil)
    end

    ## Merge the provided User's SSO details into the current user and drop the provided user to ensure the unity
    ## @param sso_user {User} the provided user will be DELETED after the merge was successful
    def merge_from_sso(sso_user)
      logger = SsoLogger.new
      logger.debug "[User::merge_from_sso] initiated with parameter #{sso_user}"
      # update the attributes to link the account to the sso account
      self.provider = sso_user.provider
      self.uid = sso_user.uid

      # remove the token
      self.auth_token = nil
      self.merged_at = Time.current

      # check that the email duplication was resolved
      if sso_user.email.end_with? '-duplicate'
        email_addr = sso_user.email.match(/^<([^>]+)>.{20}-duplicate$/)[1]
        logger.error 'duplicate email was not resolved'
        raise(DuplicateIndexError, email_addr) unless email_addr == email
      end

      # update the user's profile to set the data managed by the SSO
      auth_provider = AuthProvider.from_strategy_name(sso_user.provider)
      logger.debug "found auth_provider=#{auth_provider&.name}"
      auth_provider&.sso_fields&.each do |field|
        value = sso_user.get_data_from_sso_mapping(field)
        logger.debug "mapping sso field #{field} with value=#{value}"
        # We do not merge the email field if its end with the special value '-duplicate' as this means
        # that the user is currently merging with the account that have the same email than the sso.
        # Moreover, if the user is an administrator, we must keep him in his group
        unless (field == 'user.email' && value.end_with?('-duplicate')) || (field == 'user.group_id' && admin?)
          set_data_from_sso_mapping(field, value)
        end
      end

      # run the account transfer in an SQL transaction to ensure data integrity
      begin
        User.transaction do
          # remove the temporary account
          logger.debug 'removing the temporary user'
          sso_user.destroy
          # finally, save the new details
          logger.debug 'saving the updated user'
          save!
        end
      rescue ActiveRecord::RecordInvalid => e
        logger.error "error while merging user #{sso_user.id} into #{id}: #{e.message}"
        raise e
      end
    end
  end

  class_methods do
    def from_omniauth(auth)
      logger = SsoLogger.new
      logger.debug "[User::from_omniauth] initiated with parameter #{auth}"
      active_provider = Rails.configuration.auth_provider
      raise SecurityError, 'The identity provider does not match the activated one' if active_provider.strategy_name != auth.provider

      where(provider: auth.provider, uid: auth.uid).first_or_create.tap do |user|
        # execute this regardless of whether record exists or not (-> User#tap)
        # this will init or update the user thanks to the information retrieved from the SSO
        logger.debug user.id.nil? ? 'no user found, creating a new one' : "found user id=#{user.id}"
        user.profile ||= Profile.new
        auth.info.mapping.each do |key, value|
          logger.debug "mapping info #{key} with value=#{value}"
          user.set_data_from_sso_mapping(key, value)
        end
        logger.debug 'generating a new password'
        user.password = SecurePassword.generate
      end
    end
  end
end
