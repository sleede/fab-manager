# frozen_string_literal:true

class AddProfileUrlToOAuth2Providers < ActiveRecord::Migration[4.2]
  def change
    add_column :o_auth2_providers, :profile_url, :string
  end
end
