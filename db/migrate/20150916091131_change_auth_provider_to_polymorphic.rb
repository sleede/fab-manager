class ChangeAuthProviderToPolymorphic < ActiveRecord::Migration
  def change
    remove_column :o_auth2_providers, :auth_provider_id, :integer
    remove_column :auth_providers, :type, :string

    add_column :auth_providers, :providable_type, :string
    add_column :auth_providers, :providable_id, :integer
  end
end
