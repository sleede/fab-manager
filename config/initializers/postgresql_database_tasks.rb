# frozen_string_literal: true

# The following magic allows to drop a PG database even if a connection exists
# @see https://stackoverflow.com/a/38710021
class ActiveRecord::Tasks::PostgreSQLDatabaseTasks
  include ActiveRecord::Sanitization::ClassMethods

  def drop
    establish_master_connection
    q = sanitize_sql_array [
      "select pg_terminate_backend(pg_stat_activity.pid) from pg_stat_activity where datname= ? AND state='idle';",
      configuration_hash[:database]
    ]
    connection.select_all q
    connection.drop_database configuration_hash[:database]
  end
end
