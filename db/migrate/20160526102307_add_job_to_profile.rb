# frozen_string_literal:true

class AddJobToProfile < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :job, :string
  end
end
