# frozen_string_literal: true

# Add single sign on functionalities to the user model
module SingleSignOnConcern
  extend ActiveSupport::Concern
  require 'sso_logger'

  included do
    # enable OmniAuth authentication only if needed
    devise :omniauthable, omniauth_providers: [AuthProvider.active.strategy_name.to_sym] unless
      AuthProvider.active.providable_type == DatabaseProvider.name

    ## Retrieve the requested data in the User and user's Profile tables
    ## @param sso_mapping {String} must be of form 'user._field_' or 'profile._field_'. Eg. 'user.email'
    def get_data_from_sso_mapping(sso_mapping)
      parsed = /^(user|profile)\.(.+)$/.match(sso_mapping)
      if parsed[1] == 'user'
        self[parsed[2].to_sym]
      elsif parsed[1] == 'profile'
        case sso_mapping
        when 'profile.avatar'
          profile.user_avatar.remote_attachment_url
        when 'profile.address'
          invoicing_profile.address.address
        when 'profile.organization_name'
          invoicing_profile.organization.name
        when 'profile.organization_address'
          invoicing_profile.organization.address.address
        when 'profile.gender'
          statistic_profile.gender
        when 'profile.birthday'
          statistic_profile.birthday
        else
          profile[parsed[2].to_sym]
        end
      end
    end

    ## Set some data on the current user, according to the sso_key given
    ## @param sso_mapping {String} must be of form 'user._field_' or 'profile._field_'. Eg. 'user.email'
    ## @param data {*} the data to put in the given key. Eg. 'user@example.com'
    def set_data_from_sso_mapping(sso_mapping, data)
      if sso_mapping.to_s.start_with? 'user.'
        self[sso_mapping[5..-1].to_sym] = data unless data.nil?
      elsif sso_mapping.to_s.start_with? 'profile.'
        case sso_mapping.to_s
        when 'profile.avatar'
          profile.user_avatar ||= UserAvatar.new
          profile.user_avatar.remote_attachment_url = data
        when 'profile.address'
          invoicing_profile ||= InvoicingProfile.new
          invoicing_profile.address ||= Address.new
          invoicing_profile.address.address = data
        when 'profile.organization_name'
          invoicing_profile ||= InvoicingProfile.new
          invoicing_profile.organization ||= Organization.new
          invoicing_profile.organization.name = data
        when 'profile.organization_address'
          invoicing_profile ||= InvoicingProfile.new
          invoicing_profile.organization ||= Organization.new
          invoicing_profile.organization.address ||= Address.new
          invoicing_profile.organization.address.address = data
        when 'profile.gender'
          statistic_profile ||= StatisticProfile.new
          statistic_profile.gender = data
        when 'profile.birthday'
          statistic_profile ||= StatisticProfile.new
          statistic_profile.birthday = data
        else
          profile[sso_mapping[8..-1].to_sym] = data unless data.nil?
        end
      end
    end

    ## used to allow the migration of existing users between authentication providers
    def generate_auth_migration_token
      update_attributes(auth_token: Devise.friendly_token)
    end

    ## link the current user to the given provider (omniauth attributes hash)
    ## and remove the auth_token to mark his account as "migrated"
    def link_with_omniauth_provider(auth)
      active_provider = AuthProvider.active
      raise SecurityError, 'The identity provider does not match the activated one' if active_provider.strategy_name != auth.provider

      if User.where(provider: auth.provider, uid: auth.uid).size.positive?
        raise DuplicateIndexError, "This #{active_provider.name} account is already linked to an existing user"
      end

      update_attributes(provider: auth.provider, uid: auth.uid, auth_token: nil)
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
      self.merged_at = DateTime.current

      # check that the email duplication was resolved
      if sso_user.email.end_with? '-duplicate'
        email_addr = sso_user.email.match(/^<([^>]+)>.{20}-duplicate$/)[1]
        logger.error 'duplicate email was not resolved'
        raise(DuplicateIndexError, email_addr) unless email_addr == email
      end

      # update the user's profile to set the data managed by the SSO
      auth_provider = AuthProvider.from_strategy_name(sso_user.provider)
      logger.debug "found auth_provider=#{auth_provider.name}"
      auth_provider.sso_fields.each do |field|
        value = sso_user.get_data_from_sso_mapping(field)
        logger.debug "mapping sso field #{field} with value=#{value}"
        # we do not merge the email field if its end with the special value '-duplicate' as this means
        # that the user is currently merging with the account that have the same email than the sso
        set_data_from_sso_mapping(field, value) unless field == 'user.email' && value.end_with?('-duplicate')
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
      active_provider = AuthProvider.active
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
        user.password = Devise.friendly_token[0, 20]
      end
    end
  end
end
