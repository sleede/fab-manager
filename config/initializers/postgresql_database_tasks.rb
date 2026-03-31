# frozen_string_literal: true

# Keeps generated PostgreSQL structure dumps loadable on older supported servers.
module PostgreSQLDatabaseTasksCompatibility
  UNSUPPORTED_STRUCTURE_SQL_SETTINGS = [
    'SET transaction_timeout = '
  ].freeze

  def structure_dump(filename, extra_flags)
    super
    rewrite_structure_sql(filename)
  end

  def structure_load(filename, extra_flags)
    compatible_file = Tempfile.new(['structure', '.sql'])
    copy_structure_sql(filename, compatible_file)
    compatible_file.flush

    super(compatible_file.path, extra_flags)
  ensure
    compatible_file&.close!
  end

  private

  def rewrite_structure_sql(filename)
    compatible_file = Tempfile.new(['structure', '.sql'])
    copy_structure_sql(filename, compatible_file)
    compatible_file.flush
    FileUtils.cp(compatible_file.path, filename)
  ensure
    compatible_file&.close!
  end

  def copy_structure_sql(source_filename, target_file)
    File.foreach(source_filename) do |line|
      target_file << line unless unsupported_structure_sql_setting?(line)
    end
  end

  def unsupported_structure_sql_setting?(line)
    UNSUPPORTED_STRUCTURE_SQL_SETTINGS.any? { |setting| line.start_with?(setting) }
  end
end

# The following magic allows to drop a PG database even if a connection exists
# @see https://stackoverflow.com/a/38710021
class ActiveRecord::Tasks::PostgreSQLDatabaseTasks
  prepend PostgreSQLDatabaseTasksCompatibility
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
