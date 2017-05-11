class AddCharacteristicsToSpace < ActiveRecord::Migration
  def change
    add_column :spaces, :characteristics, :text
  end
end
