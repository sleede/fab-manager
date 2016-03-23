class AddProfileUrlToOAuth2Providers < ActiveRecord::Migration
  def change
    add_column :o_auth2_providers, :profile_url, :string
  end
end
