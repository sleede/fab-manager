# frozen_string_literal: true

# Validates the presence of the User.uid mapping
class OAuth2ProviderValidator < ActiveModel::Validator
  def validate(record)
    return unless record.providable_type == 'OAuth2Provider'

    return if record.auth_provider_mappings.any? do |mapping|
      mapping.local_model == 'user' && mapping.local_field == 'uid'
    end

    record.errors.add(:uid, I18n.t('app.admin.authentication_new.it_is_required_to_set_the_matching_between_User.uid_and_the_API_to_add_this_provider'))
  end
end
