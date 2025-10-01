# frozen_string_literal:true

class ChangeIsAllowContactDefault < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :is_allow_contact, from: true, to: false
  end
end
