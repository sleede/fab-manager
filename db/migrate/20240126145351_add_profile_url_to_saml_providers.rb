# frozen_string_literal:true

class AddProfileUrlToSamlProviders < ActiveRecord::Migration[7.0]
  def change
    add_column :saml_providers, :profile_url, :string
s end
end
