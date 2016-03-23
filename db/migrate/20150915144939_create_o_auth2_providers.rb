class CreateOAuth2Providers < ActiveRecord::Migration
  def change
    create_table :o_auth2_providers do |t|
      t.string :base_url
      t.string :token_endpoint
      t.string :authorization_endpoint
      t.string :client_id
      t.string :client_secret
      t.belongs_to :auth_provider, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
