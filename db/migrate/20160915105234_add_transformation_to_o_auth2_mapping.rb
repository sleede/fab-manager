class AddTransformationToOAuth2Mapping < ActiveRecord::Migration
  def change
    add_column :o_auth2_mappings, :transformation, :jsonb
  end
end
