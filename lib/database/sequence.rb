# frozen_string_literal: true

# Database helpers
module Database; end

# Manage sequences
class Database::Sequence
  class << self
    # update the ID sequence for the given table
    # @param table_name [String]
    def update_id_seq(table_name)
      return unless ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'postgresql'

      ActiveRecord::Base.connection.execute <<~SQL.squish
        WITH max_id AS (
         SELECT max(id) as max FROM #{table_name}
        )
        SELECT setval('#{table_name}_id_seq', max_id.max)
        FROM max_id;
      SQL
    end
  end
end
