# frozen_string_literal: true

# Validates there's only one database provider
class DatabaseProviderValidator < ActiveModel::Validator
  def validate(record)
    return if DatabaseProvider.count.zero?

    record.errors.add(:id, I18n.t('authentication_providers.local_database_provider_already_exists'))
  end
end
