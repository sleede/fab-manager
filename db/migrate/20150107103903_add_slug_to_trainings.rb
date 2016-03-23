class AddSlugToTrainings < ActiveRecord::Migration
  def up
    add_column :trainings, :slug, :string
    add_index :trainings, :slug, unique: true

    Training.all.each do |t|
      slug = t.send(:set_slug) || t.slug
      t.update_columns(slug: slug)
    end
  end

  def down
    remove_column :trainings, :slug, :string
    remove_index :trainings, :slug, unique: true
  end
end
