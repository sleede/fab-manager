class AddProfileToOrganization < ActiveRecord::Migration
  def change
    add_reference :organizations, :profile, index: true, foreign_key: true
  end
end
