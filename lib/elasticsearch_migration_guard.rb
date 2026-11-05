# frozen_string_literal: true

require 'json'
require 'date'

# Temporary, fail-closed maintenance and historical-data fence for an explicit migration.
module ElasticsearchMigrationGuard
  class Held < StandardError; end

  def self.configuration
    path = ENV.fetch('ES_MIGRATION_GUARD', nil)
    return nil if path.blank?

    raise Held, 'Migration guard missing or oversized' unless File.file?(path) && File.size(path) < 16_384

    JSON.parse(File.read(path)).tap do |guard|
      %w[phase run_id queue_prefix protected_through].each { |key| guard.fetch(key) }
    end
  rescue JSON::ParserError, KeyError => e
    raise Held, "Invalid migration guard: #{e.class}"
  end

  def self.write!(client)
    guard = configuration
    return unless guard

    raise Held, 'Elasticsearch writes remain closed for migration' unless guard['phase'] == 'writes_open'
    raise Held, 'Wrong migration target cluster' unless client.info['cluster_uuid'] == guard.fetch('target_cluster_uuid')
  end

  def self.rebuild!(options)
    guard = configuration
    return unless guard

    raise Held, 'Historical statistics require explicit reconciliation, not automatic regeneration' if
      guard['phase'] != 'writes_open' || options[:start_date].to_date <= Date.iso8601(guard.fetch('protected_through'))
  end

  # Old scheduled/retry jobs keep their original queue. New jobs use an isolated namespace.
  class ClientMiddleware
    def call(_worker_class, job, _queue, _redis_pool)
      guard = ElasticsearchMigrationGuard.configuration
      if guard
        raise Held, 'Job production remains closed for migration' unless guard['phase'] == 'writes_open'

        if job['created_at'] && job['created_at'].to_f >= guard.fetch('reopened_at').to_f
          prefix = guard.fetch('queue_prefix')
          job['queue'] = prefix + job.fetch('queue') unless job.fetch('queue').start_with?(prefix)
        end
      end
      yield
    end
  end

  # Defense in depth: server startup also rejects consumption of an old queue.
  class ServerMiddleware
    def call(_worker, job, queue)
      guard = ElasticsearchMigrationGuard.configuration
      if guard && (guard['phase'] != 'writes_open' || !queue.start_with?(guard.fetch('queue_prefix')) ||
                   !job['created_at'] || job['created_at'].to_f < guard.fetch('reopened_at').to_f)
        raise Held, 'Legacy job held for migration review; original Redis backup is retained'
      end

      yield
    end
  end

  # Workers consume only the new namespace. Configured queue names (config/sidekiq.yml, weights
  # included) are mapped onto it, so the shipped worker command keeps every queue without ever
  # consuming a legacy queue.
  def self.worker_queues!(queues)
    guard = configuration
    return queues unless guard
    raise Held, 'Workers remain stopped until migration writes reopen' unless guard['phase'] == 'writes_open' && queues.present?

    prefix = guard.fetch('queue_prefix')
    queues.map { |queue| queue.start_with?(prefix) ? queue : prefix + queue }
  end
end
