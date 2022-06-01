# frozen_string_literal: true

# Previously, the OpenID Connect scope was a string, scopes were separated by commas.
# To be more fron-end friendly, we now use an array.
class ChangeOidcScopeToArray < ActiveRecord::Migration[5.2]
  def change
    change_column :open_id_connect_providers, :scope, "varchar[] USING (string_to_array(scope, ','))"
  end
end
