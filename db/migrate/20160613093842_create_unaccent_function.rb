class CreateUnaccentFunction < ActiveRecord::Migration

  # PostgreSQL only
  def up
    execute 'CREATE EXTENSION IF NOT EXISTS unaccent;'
    execute 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'
    execute "CREATE OR REPLACE FUNCTION f_unaccent(text)
               RETURNS text AS
             $func$
             SELECT public.unaccent('public.unaccent', $1)
             $func$  LANGUAGE sql IMMUTABLE;"
    execute 'CREATE INDEX profiles_lower_unaccent_first_name_trgm_idx ON profiles
             USING gin (lower(f_unaccent(first_name)) gin_trgm_ops);'
    execute 'CREATE INDEX profiles_lower_unaccent_last_name_trgm_idx ON profiles
             USING gin (lower(f_unaccent(last_name)) gin_trgm_ops);'
  end

  def down
    execute 'DROP INDEX profiles_lower_unaccent_first_name_trgm_idx;'
    execute 'DROP INDEX profiles_lower_unaccent_last_name_trgm_idx;'
    execute 'DROP FUNCTION f_unaccent(text);'
    execute 'DROP EXTENSION pg_trgm;'
    execute 'DROP EXTENSION unaccent;'
  end
end
