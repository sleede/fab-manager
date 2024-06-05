# frozen_string_literal: true

class AddUidAttributeToSamlProvider < ActiveRecord::Migration[7.0]
  def change
    add_column :saml_providers, :uid_attribute, :string
  end
end
