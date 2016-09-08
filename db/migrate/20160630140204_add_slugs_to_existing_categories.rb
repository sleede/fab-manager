class AddSlugsToExistingCategories < ActiveRecord::Migration
  def up
    execute 'UPDATE categories
             SET slug=name
             WHERE slug IS NULL;'
  end

  def down
    execute 'UPDATE categories
             SET slug=NULL
             WHERE slug=name;'
  end
end
