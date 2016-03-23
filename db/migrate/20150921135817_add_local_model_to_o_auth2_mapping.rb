class AddLocalModelToOAuth2Mapping < ActiveRecord::Migration
  def change
    add_column :o_auth2_mappings, :local_model, :string
  end
end
