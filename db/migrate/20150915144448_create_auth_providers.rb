class CreateAuthProviders < ActiveRecord::Migration
  def change
    create_table :auth_providers do |t|
      t.string :name
      t.string :type
      t.string :status

      t.timestamps null: false
    end
  end
end
