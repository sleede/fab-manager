# frozen_string_literal:true

class AddKeyToExport < ActiveRecord::Migration[4.2]
  def change
    add_column :exports, :key, :string
  end
end
