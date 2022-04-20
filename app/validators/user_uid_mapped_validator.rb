# frozen_string_literal: true

# Validates the presence of the User.uid mapping
class UserUidMappedValidator < ActiveModel::Validator
  def validate(record)
    return unless %w[OAuth2Provider OpenIdConnectProvider].include?(record.providable_type)

    return if record.auth_provider_mappings.any? do |mapping|
      mapping.local_model == 'user' && mapping.local_field == 'uid'
    end

    record.errors.add(:uid, I18n.t('authentication_providers.matching_between_User_uid_and_API_required'))
  end
end
