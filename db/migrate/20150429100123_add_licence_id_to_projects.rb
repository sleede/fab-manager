class AddLicenceIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :licence_id, :integer
  end
end
