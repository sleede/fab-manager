class AddOrganizationToProfile < ActiveRecord::Migration
  def change
    add_reference :profiles, :organization, index: true, foreign_key: true
  end
end
