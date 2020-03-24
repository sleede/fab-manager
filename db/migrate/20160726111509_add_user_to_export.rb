# frozen_string_literal:true

class AddUserToExport < ActiveRecord::Migration[4.2]
  def change
    add_reference :exports, :user, index: true, foreign_key: true
  end
end
