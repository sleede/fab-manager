# frozen_string_literal: true

# Index for full-text search in projects
class AddSearchVectorToProject < ActiveRecord::Migration[5.2]
  def self.up
    add_column :projects, :search_vector, :tsvector

    execute <<-SQL
      CREATE INDEX projects_search_vector_idx ON projects USING gin(search_vector);
    SQL
  end

  def self.down
    remove_column :projects, :search_vector
  end
end
