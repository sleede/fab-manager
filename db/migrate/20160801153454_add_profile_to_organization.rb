# frozen_string_literal:true

class AddProfileToOrganization < ActiveRecord::Migration[4.2]
  def change
    add_reference :organizations, :profile, index: true, foreign_key: true
  end
end
