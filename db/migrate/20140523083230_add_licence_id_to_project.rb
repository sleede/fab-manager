# frozen_string_literal:true

class AddLicenceIdToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :licence_id, :integer
  end
end