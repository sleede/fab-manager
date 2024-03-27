# frozen_string_literal: true

class AddSpCertificateToSamlProvider < ActiveRecord::Migration[7.0]
  def change
    add_column :saml_providers, :sp_certificate, :string
    add_column :saml_providers, :sp_private_key, :string
    add_column :saml_providers, :authn_requests_signed, :boolean, default: false
    add_column :saml_providers, :want_assertions_signed, :boolean, default: false
  end
end
