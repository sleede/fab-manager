class CreateOAuth2Mappings < ActiveRecord::Migration
  def change
    create_table :o_auth2_mappings do |t|
      t.belongs_to :o_auth2_provider, index: true, foreign_key: true
      t.string :resource_url
      t.string :local_field
      t.string :api_field
      t.string :data_type

      t.timestamps null: false
    end
  end
end
