# frozen_string_literal: true

# Validates there's only one database provider
class DatabaseProviderValidator < ActiveModel::Validator
  def validate(record)
    return if DatabaseProvider.count.zero?

    record.errors[:id] << I18n.t('app.admin.authentication_new.a_local_database_provider_already_exists_unable_to_create_another')
  end
end
