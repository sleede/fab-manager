# frozen_string_literal:true

class AddTransformationToOAuth2Mapping < ActiveRecord::Migration[4.2]
  def change
    add_column :o_auth2_mappings, :transformation, :jsonb
  end
end
