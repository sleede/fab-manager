# frozen_string_literal: true

# Test-only job, consumed by a real Sidekiq process in the isolated migration network.
class MigrationDatabaseProbeWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'migration_probe', retry: false

  def perform(run_id, delay = 0)
    sleep delay
    connection = ActiveRecord::Base.connection
    connection.execute <<~SQL.squish
      INSERT INTO migration_worker_probes(run_id,database_version,users_count,invoice_cents)
      SELECT #{connection.quote(run_id)}, current_setting('server_version_num')::integer,
             (SELECT count(*) FROM users), (SELECT COALESCE(sum(total),0) FROM invoices)
    SQL
  end
end
