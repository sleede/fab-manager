class AddUserToExport < ActiveRecord::Migration
  def change
    add_reference :exports, :user, index: true, foreign_key: true
  end
end
