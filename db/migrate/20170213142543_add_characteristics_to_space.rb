# frozen_string_literal:true

class AddCharacteristicsToSpace < ActiveRecord::Migration[4.2]
  def change
    add_column :spaces, :characteristics, :text
  end
end
