# frozen_string_literal: true

# Previously, the AuthProviderMapping was saving an o_auth2_provider_id.
# This migration migrates that data to bind the mappings directly to an AuthProvider as this table is now protocol-generic.
class MigrateOAuth2ProviderIdFromAuthProviderMappings < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
      UPDATE auth_provider_mappings
      SET auth_provider_id = auth_providers.id
      FROM o_auth2_providers
        INNER JOIN auth_providers ON auth_providers.providable_id = o_auth2_providers.id
        AND auth_providers.providable_type = 'OAuth2Provider'
      WHERE auth_provider_mappings.o_auth2_provider_id = o_auth2_providers.id
    SQL

    remove_reference :auth_provider_mappings, :o_auth2_provider, index: true, foreign_key: true
  end

  def down
    add_reference :auth_provider_mappings, :o_auth2_provider, index: true, foreign_key: true

    execute <<~SQL
      UPDATE auth_provider_mappings
      SET o_auth2_provider_id = o_auth2_providers.id
      FROM o_auth2_providers
        INNER JOIN auth_providers ON auth_providers.providable_id = o_auth2_providers.id
        AND auth_providers.providable_type = 'OAuth2Provider'
      WHERE auth_provider_mappings.auth_provider_id = auth_providers.id
    SQL
  end
end
