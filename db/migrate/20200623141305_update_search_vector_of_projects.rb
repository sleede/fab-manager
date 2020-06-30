# frozen_string_literal: true

# Create a PL/pgSQL function and trigger it on records update.
# This function will update the Project::search_vector according to the saved project
class UpdateSearchVectorOfProjects < ActiveRecord::Migration[5.2]
  # PostgreSQL only
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION fill_search_vector_for_project() RETURNS trigger LANGUAGE plpgsql AS $$
      declare
        step_title record;
        step_description record;

      begin
        select title into step_title from project_steps where project_id = new.id;
        select string_agg(description, ' ') as content into step_description from project_steps where project_id = new.id;

        new.search_vector :=
          setweight(to_tsvector('pg_catalog.#{Rails.application.secrets.postgresql_language_analyzer}', unaccent(coalesce(new.name, ''))), 'A') ||
          setweight(to_tsvector('pg_catalog.#{Rails.application.secrets.postgresql_language_analyzer}', unaccent(coalesce(new.tags, ''))), 'B') ||
          setweight(to_tsvector('pg_catalog.#{Rails.application.secrets.postgresql_language_analyzer}', unaccent(coalesce(new.description, ''))), 'D') ||
          setweight(to_tsvector('pg_catalog.#{Rails.application.secrets.postgresql_language_analyzer}', unaccent(coalesce(step_title.title, ''))), 'C') ||
          setweight(to_tsvector('pg_catalog.#{Rails.application.secrets.postgresql_language_analyzer}', unaccent(coalesce(step_description.content, ''))), 'D');

        return new;
      end
      $$;
    SQL

    execute <<-SQL
      CREATE TRIGGER projects_search_content_trigger BEFORE INSERT OR UPDATE
        ON projects FOR EACH ROW EXECUTE PROCEDURE fill_search_vector_for_project();
    SQL

    Project.find_each(&:touch)
  end

  def down
    execute <<-SQL
      DROP TRIGGER projects_search_content_trigger ON projects;
      DROP FUNCTION fill_search_vector_for_project();
    SQL
  end
end
