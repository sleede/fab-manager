class RemoveProfileFromOrganization < ActiveRecord::Migration
  def change
    remove_reference :organizations, :profile, index: true, foreign_key: true
  end
end
