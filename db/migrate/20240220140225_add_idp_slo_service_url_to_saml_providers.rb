class AddIdpSloServiceUrlToSamlProviders < ActiveRecord::Migration[7.0]
  def change
    add_column :saml_providers, :idp_slo_service_url, :string
  end
end
