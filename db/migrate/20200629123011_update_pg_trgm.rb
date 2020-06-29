# frozen_string_literal: true

# Recreate the pg_trgm extension to upgrade from v1.1 to v1.3
# This will enable the function word_similarity(text, text) for the project's full-text searches
class UpdatePgTrgm < ActiveRecord::Migration[5.2]
  # PostgreSQL only
  def change
    say_with_time('Upgrade extension :pg_trgm') do
      execute <<~SQL
        DROP INDEX profiles_lower_unaccent_first_name_trgm_idx;
        DROP INDEX profiles_lower_unaccent_last_name_trgm_idx;
        DROP EXTENSION pg_trgm;
        CREATE EXTENSION IF NOT EXISTS pg_trgm;
        CREATE INDEX profiles_lower_unaccent_first_name_trgm_idx ON profiles
             USING gin (lower(f_unaccent(first_name)) gin_trgm_ops);
        CREATE INDEX profiles_lower_unaccent_last_name_trgm_idx ON profiles
             USING gin (lower(f_unaccent(last_name)) gin_trgm_ops);
      SQL
    end
  end
end
