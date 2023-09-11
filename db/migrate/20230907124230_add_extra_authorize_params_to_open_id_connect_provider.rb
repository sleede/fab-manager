class AddExtraAuthorizeParamsToOpenIdConnectProvider < ActiveRecord::Migration[7.0]
  def change
    add_column :open_id_connect_providers, :extra_authorize_params, :jsonb, default: {}
  end
end
