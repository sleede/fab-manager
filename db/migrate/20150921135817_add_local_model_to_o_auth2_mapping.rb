# frozen_string_literal:true

class AddLocalModelToOAuth2Mapping < ActiveRecord::Migration[4.2]
  def change
    add_column :o_auth2_mappings, :local_model, :string
  end
end
