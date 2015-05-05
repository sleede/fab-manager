class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.string :slug
      t.datetime :published_at
      t.integer :author_id
      t.text :tags
      t.string :state

      t.timestamps
    end
    add_index :projects, :slug, unique: true
  end
end
