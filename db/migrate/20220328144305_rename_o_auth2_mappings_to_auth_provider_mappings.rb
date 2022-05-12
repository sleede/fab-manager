# frozen_string_literal: true

# This migration renames the OAuth2Mappings table to AuthProviderMappings because the
# field mapping is common to all kinds of single-sign-on providers.
class RenameOAuth2MappingsToAuthProviderMappings < ActiveRecord::Migration[5.2]
  def change
    rename_table :o_auth2_mappings, :auth_provider_mappings
    add_reference :auth_provider_mappings, :auth_provider, index: true, foreign_key: true

  end
end
