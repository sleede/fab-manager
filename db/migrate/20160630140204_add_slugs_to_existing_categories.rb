# frozen_string_literal:true

class AddSlugsToExistingCategories < ActiveRecord::Migration[4.2]
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
