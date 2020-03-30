# frozen_string_literal:true

class AddExtensionToExport < ActiveRecord::Migration[4.2]
  def change
    add_column :exports, :extension, :string, default: 'xlsx'
  end
end
