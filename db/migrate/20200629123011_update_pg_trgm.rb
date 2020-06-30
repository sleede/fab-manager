# frozen_string_literal: true

# Recreate the pg_trgm extension to upgrade from v1.1 to v1.3
# This will enable the function word_similarity(text, text) for the project's full-text searches
class UpdatePgTrgm < ActiveRecord::Migration[5.2]
  # PostgreSQL only
  def up
    say_with_time('Upgrade extension :pg_trgm') do
      execute <<~SQL
        ALTER EXTENSION pg_trgm UPDATE;
      SQL
    end
  end

  def down
    # we cannot downgrade a postgresSQL extension, so we do notinf
    execute <<~SQL
      ALTER EXTENSION pg_trgm UPDATE;
    SQL
  end
end
