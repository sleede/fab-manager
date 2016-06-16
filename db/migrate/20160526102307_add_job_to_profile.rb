class AddJobToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :job, :string
  end
end
