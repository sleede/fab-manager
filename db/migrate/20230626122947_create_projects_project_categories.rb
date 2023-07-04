class CreateProjectsProjectCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :projects_project_categories do |t|
      t.belongs_to :project, foreign_key: true, null: false
      t.belongs_to :project_category, foreign_key: true, null: false

      t.timestamps
    end

    add_index :projects_project_categories, [:project_id, :project_category_id], unique: true, name: :idx_projects_project_categories
  end
end
