# frozen_string_literal: true

# Create a PostgreSQL specific function to make pg_search gem working with fuzzystrmatch
class AddPgSearchDmetaphoneSupportFunctions < ActiveRecord::Migration[5.2]
  def self.up
    say_with_time('Adding support functions for pg_search :dmetaphone') do
      execute 'CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;'
      execute <<~'SQL'
        CREATE OR REPLACE FUNCTION pg_search_dmetaphone(text) RETURNS text LANGUAGE SQL IMMUTABLE STRICT AS $function$
          SELECT array_to_string(ARRAY(SELECT dmetaphone(unnest(regexp_split_to_array($1, E'\\s+')))), ' ')
        $function$;
      SQL
    end
  end

  def self.down
    say_with_time('Dropping support functions for pg_search :dmetaphone') do
      execute <<~'SQL'
        DROP FUNCTION pg_search_dmetaphone(text);
      SQL
      execute 'DROP EXTENSION IF EXISTS fuzzystrmatch;'
    end
  end
end
