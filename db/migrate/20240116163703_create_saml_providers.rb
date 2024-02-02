class CreateSamlProviders < ActiveRecord::Migration[7.0]
  def change
    create_table :saml_providers do |t|
      t.string :sp_entity_id
      t.string :idp_sso_service_url

      t.timestamps
    end
  end
end
