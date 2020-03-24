# frozen_string_literal:true

class AddGroupToUser < ActiveRecord::Migration[4.2]
  def change
    add_reference :users, :group, index: true
  end
end
