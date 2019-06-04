class RemoveGenderBirthdayFromProfile < ActiveRecord::Migration
  def change
    remove_column :profiles, :gender, :boolean
    remove_column :profiles, :birthday, :date
  end
end
