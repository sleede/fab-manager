class AddAncestryToSpaces < ActiveRecord::Migration[7.0]
  def change
    add_column :spaces, :ancestry, :string, collation: 'C'
    Space.update_all(ancestry: '/')
    change_column_null(:spaces, :ancestry, false)
    add_column :spaces, :ancestry_depth, :integer, default: 0
    add_index :spaces, :ancestry
  end
end
