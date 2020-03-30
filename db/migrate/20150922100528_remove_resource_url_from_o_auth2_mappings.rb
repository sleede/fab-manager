# frozen_string_literal:true

class RemoveResourceUrlFromOAuth2Mappings < ActiveRecord::Migration[4.2]
  def change
    remove_column :o_auth2_mappings, :resource_url, :string
    remove_column :o_auth2_mappings, :data_type, :string
  end
end
