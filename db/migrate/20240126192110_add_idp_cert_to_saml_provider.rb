class AddIdpCertToSamlProvider < ActiveRecord::Migration[7.0]
  def change
    add_column :saml_providers, :idp_cert, :string
    add_column :saml_providers, :idp_cert_fingerprint, :string
  end
end
